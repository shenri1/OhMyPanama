#!/bin/bash

# ==============================================================================
# OhMyPanama - System Configuration Module
# Description: Configures shell, security, and system-wide settings
# Author: Silas Henrique
# ==============================================================================

set -e
set -o pipefail

LOG_FILE="$HOME/.local/state/ohmypanama/system.log"

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================
log_info() {
    echo "[INFO] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo "[✓] $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo "[!] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[✗] $1" | tee -a "$LOG_FILE"
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================
command_exists() {
    command -v "$1" &> /dev/null
}

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_info "Backed up $file to $backup"
    fi
}

# ==============================================================================
# MAIN MODULE
# ==============================================================================
log_info "=========================================="
log_info "  System Configuration Module"
log_info "=========================================="

mkdir -p "$(dirname "$LOG_FILE")"

# ==============================================================================
# 1. ZSH CONFIGURATION
# ==============================================================================
configure_zsh() {
    log_info "Configuring Zsh..."

    # Check if Zsh is installed
    if ! command_exists zsh; then
        log_warning "Zsh is not installed. Installing..."
        sudo dnf install -y zsh
    fi

    # Set Zsh as default shell
    if [ "$SHELL" != "/usr/bin/zsh" ] && [ -x "/usr/bin/zsh" ]; then
        log_info "Setting Zsh as default shell..."
        if sudo chsh -s /usr/bin/zsh "$USER"; then
            log_success "Zsh set as default shell (requires logout)"
        else
            log_error "Failed to set Zsh as default shell"
            return 1
        fi
    else
        log_success "Zsh already set as default shell"
    fi

    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh My Zsh..."
        export RUNZSH=no
        export KEEP_ZSHRC=yes

        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Oh My Zsh installed successfully"
        else
            log_error "Failed to install Oh My Zsh"
            return 1
        fi
    else
        log_success "Oh My Zsh already installed"
    fi
}

# ==============================================================================
# 2. SHELL PLUGINS CONFIGURATION
# ==============================================================================
configure_shell_plugins() {
    log_info "Configuring shell plugins..."

    local ZSHRC="$HOME/.zshrc"

    if [ ! -f "$ZSHRC" ]; then
        log_warning ".zshrc not found, creating..."
        touch "$ZSHRC"
    fi

    # Backup .zshrc
    backup_file "$ZSHRC"

    # Configure Starship
    if command_exists starship; then
        if ! grep -q "starship init zsh" "$ZSHRC"; then
            log_info "Adding Starship to .zshrc..."
            echo '' >> "$ZSHRC"
            echo '# Starship Prompt' >> "$ZSHRC"
            echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
            log_success "Starship configured"
        else
            log_success "Starship already configured"
        fi
    else
        log_warning "Starship not installed, skipping configuration"
    fi

    # Configure Zoxide
    if command_exists zoxide; then
        if ! grep -q "zoxide init zsh" "$ZSHRC"; then
            log_info "Adding Zoxide to .zshrc..."
            echo '' >> "$ZSHRC"
            echo '# Zoxide (smarter cd)' >> "$ZSHRC"
            echo 'eval "$(zoxide init zsh)"' >> "$ZSHRC"
            log_success "Zoxide configured"
        else
            log_success "Zoxide already configured"
        fi
    else
        log_warning "Zoxide not installed, skipping configuration"
    fi

    # Configure Bat alias (cat replacement)
    if command_exists bat; then
        if ! grep -q "alias cat='bat'" "$ZSHRC"; then
            log_info "Adding Bat alias to .zshrc..."
            echo '' >> "$ZSHRC"
            echo '# Bat (better cat)' >> "$ZSHRC"
            echo "alias cat='bat'" >> "$ZSHRC"
            log_success "Bat alias configured"
        else
            log_success "Bat alias already configured"
        fi
    fi

    # Configure Eza alias (ls replacement)
    if command_exists eza; then
        if ! grep -q "alias ls='eza'" "$ZSHRC"; then
            log_info "Adding Eza aliases to .zshrc..."
            echo '' >> "$ZSHRC"
            echo '# Eza (better ls)' >> "$ZSHRC"
            echo "alias ls='eza --icons'" >> "$ZSHRC"
            echo "alias ll='eza -l --icons'" >> "$ZSHRC"
            echo "alias la='eza -la --icons'" >> "$ZSHRC"
            echo "alias lt='eza --tree --icons'" >> "$ZSHRC"
            log_success "Eza aliases configured"
        else
            log_success "Eza aliases already configured"
        fi
    fi

    # Add Cargo to PATH
    if [ -d "$HOME/.cargo/bin" ]; then
        if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' "$ZSHRC"; then
            log_info "Adding Cargo to PATH..."
            echo '' >> "$ZSHRC"
            echo '# Cargo (Rust)' >> "$ZSHRC"
            echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$ZSHRC"
            log_success "Cargo added to PATH"
        else
            log_success "Cargo already in PATH"
        fi
    fi

    # Add local bin to PATH
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$ZSHRC"; then
        log_info "Adding local bin to PATH..."
        echo '' >> "$ZSHRC"
        echo '# Local binaries' >> "$ZSHRC"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
        log_success "Local bin added to PATH"
    fi
}

# ==============================================================================
# 3. SECURITY CONFIGURATION (UFW Firewall)
# ==============================================================================
configure_security() {
    log_info "Configuring security settings..."

    # Check if UFW is installed
    if ! command_exists ufw; then
        log_warning "UFW not installed. Installing..."
        sudo dnf install -y ufw
    fi

    # Disable firewalld if active
    if systemctl is-active --quiet firewalld; then
        log_info "Disabling firewalld in favor of UFW..."
        sudo systemctl stop firewalld
        sudo systemctl disable firewalld
        sudo systemctl mask firewalld
        log_success "Firewalld disabled"
    fi

    # Configure UFW
    log_info "Configuring UFW firewall..."

    # Enable UFW service
    sudo systemctl enable ufw &> /dev/null

    # Set default policies
    sudo ufw --force default deny incoming 2>&1 | tee -a "$LOG_FILE"
    sudo ufw --force default allow outgoing 2>&1 | tee -a "$LOG_FILE"

    # Allow SSH (important for remote access)
    sudo ufw --force allow ssh 2>&1 | tee -a "$LOG_FILE"

    # Enable UFW
    sudo ufw --force enable 2>&1 | tee -a "$LOG_FILE"

    log_success "UFW firewall configured and enabled"

    # Display UFW status
    log_info "Current UFW status:"
    sudo ufw status verbose | tee -a "$LOG_FILE"
}

# ==============================================================================
# 4. STARSHIP CONFIGURATION
# ==============================================================================
configure_starship() {
    log_info "Configuring Starship prompt..."

    if ! command_exists starship; then
        log_warning "Starship not installed, skipping configuration"
        return
    fi

    local STARSHIP_CONFIG="$HOME/.config/starship.toml"

    if [ -f "$STARSHIP_CONFIG" ]; then
        log_success "Starship config already exists"
        return
    fi

    log_info "Creating Starship configuration..."
    mkdir -p "$HOME/.config"

    cat > "$STARSHIP_CONFIG" << 'EOF'
# OhMyPanama Starship Configuration

format = """
[┌───────────────────────────────────>](bold green)
[│](bold green)$directory$git_branch$git_status
[└─>](bold green) """

[directory]
style = "bold cyan"
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = " "
style = "bold purple"

[git_status]
style = "bold yellow"
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[cmd_duration]
min_time = 500
format = "took [$duration](bold yellow) "

[time]
disabled = false
format = '🕙[\[ $time \]]($style) '
style = "bold white"
EOF

    log_success "Starship configuration created"
}

# ==============================================================================
# 5. GIT CONFIGURATION
# ==============================================================================
configure_git() {
    log_info "Checking Git configuration..."

    if ! command_exists git; then
        log_warning "Git not installed, skipping configuration"
        return
    fi

    # Set global defaults if not set
    if [ -z "$(git config --global --get user.name)" ]; then
        log_info "Git user.name not set. You can configure it later with:"
        log_info "  git config --global user.name 'Your Name'"
    fi

    if [ -z "$(git config --global --get user.email)" ]; then
        log_info "Git user.email not set. You can configure it later with:"
        log_info "  git config --global user.email 'your.email@example.com'"
    fi

    # Set useful defaults
    git config --global init.defaultBranch main 2>/dev/null || true
    git config --global pull.rebase false 2>/dev/null || true
    git config --global core.editor "vim" 2>/dev/null || true

    log_success "Git defaults configured"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

# Execute configuration functions
configure_zsh
configure_shell_plugins
configure_security
configure_starship
configure_git

log_success "=========================================="
log_success "  System Configuration Complete!"
log_success "=========================================="
log_info "Log file: $LOG_FILE"
log_warning "Please logout and login again to apply shell changes"
