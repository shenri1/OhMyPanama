#!/bin/bash

# ==============================================================================
# OhMyPanama - Package Management Module
# Description: Manages installation from multiple package sources
# Author: Silas Henrique
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

LISTS_DIR="$(dirname "$(readlink -f "$0")")/lists"
LOG_FILE="$HOME/.local/state/ohmypanama/packages.log"

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

# Read list file, removing comments and empty lines
read_list() {
    [ -f "$1" ] && grep -vE '^\s*#|^\s*$' "$1" || echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if package is installed via DNF
is_dnf_installed() {
    rpm -q "$1" &> /dev/null
}

# Check if flatpak is installed
is_flatpak_installed() {
    flatpak list --app 2>/dev/null | grep -q "$1"
}

# ==============================================================================
# MAIN MODULE
# ==============================================================================
log_info "Package Management Module Initialized..."
mkdir -p "$(dirname "$LOG_FILE")"

# ==============================================================================
# 1. DNF (Fedora Native Packages)
# ==============================================================================
install_dnf_packages() {
    log_info "Checking DNF packages..."

    local DNF_LIST=$(read_list "$LISTS_DIR/dnf.list")
    local TO_INSTALL=""
    local ALREADY_INSTALLED=0
    local TO_INSTALL_COUNT=0

    if [ -z "$DNF_LIST" ]; then
        log_warning "No DNF packages defined in dnf.list"
        return
    fi

    # Check each package
    for pkg in $DNF_LIST; do
        if is_dnf_installed "$pkg"; then
            ((ALREADY_INSTALLED++))
        else
            log_info "Queued for installation: $pkg"
            TO_INSTALL="$TO_INSTALL $pkg"
            ((TO_INSTALL_COUNT++))
        fi
    done

    log_info "DNF Status: $ALREADY_INSTALLED already installed, $TO_INSTALL_COUNT to install"

    # Install queued packages
    if [ -n "$TO_INSTALL" ]; then
        log_info "Installing $TO_INSTALL_COUNT DNF packages..."
        if sudo dnf install -y $TO_INSTALL; then
            log_success "DNF packages installed successfully"
        else
            log_error "Some DNF packages failed to install"
            return 1
        fi
    else
        log_success "All DNF packages already installed"
    fi
}

# ==============================================================================
# 2. COPR Repositories
# ==============================================================================
install_copr_packages() {
    log_info "Processing COPR repositories..."

    local COPR_LIST_FILE="$LISTS_DIR/copr.list"

    if [ ! -f "$COPR_LIST_FILE" ]; then
        log_warning "No COPR list found, skipping..."
        return
    fi

    # Ensure DNF plugins are installed
    if ! is_dnf_installed "dnf-plugins-core"; then
        log_info "Installing dnf-plugins-core..."
        sudo dnf install -y dnf-plugins-core
    fi

    local copr_count=0
    while IFS='|' read -r repo_id packages; do
        # Skip comments and empty lines
        [[ "$repo_id" =~ ^#.*$ ]] && continue
        [[ -z "$repo_id" ]] && continue

        repo_id=$(echo "$repo_id" | xargs)
        packages=$(echo "$packages" | xargs)

        log_info "Enabling COPR repository: $repo_id"
        if sudo dnf copr enable -y "$repo_id" 2>&1 | tee -a "$LOG_FILE"; then
            ((copr_count++))

            if [ -n "$packages" ]; then
                log_info "Installing packages from $repo_id: $packages"
                sudo dnf install -y $packages 2>&1 | tee -a "$LOG_FILE"
            fi
        else
            log_error "Failed to enable COPR repo: $repo_id"
        fi
    done < "$COPR_LIST_FILE"

    log_success "Processed $copr_count COPR repositories"
}

# ==============================================================================
# 3. FLATPAK (Universal Apps)
# ==============================================================================
install_flatpak_packages() {
    log_info "Checking Flatpak packages..."

    # Ensure Flatpak is installed
    if ! command_exists flatpak; then
        log_info "Installing Flatpak..."
        sudo dnf install -y flatpak
    fi

    # Add Flathub repository
    if ! flatpak remote-list 2>/dev/null | grep -q "flathub"; then
        log_info "Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi

    local FLATPAK_LIST=$(read_list "$LISTS_DIR/flatpak.list")

    if [ -z "$FLATPAK_LIST" ]; then
        log_warning "No Flatpak packages defined"
        return
    fi

    local installed=0
    local to_install=0

    for app in $FLATPAK_LIST; do
        if is_flatpak_installed "$app"; then
            log_success "$app already installed"
            ((installed++))
        else
            log_info "Installing Flatpak: $app"
            if flatpak install -y flathub "$app" 2>&1 | tee -a "$LOG_FILE"; then
                ((to_install++))
            else
                log_error "Failed to install: $app"
            fi
        fi
    done

    log_info "Flatpak Status: $installed already installed, $to_install newly installed"
}

# ==============================================================================
# 4. CURL INSTALLERS (Web Scripts)
# ==============================================================================
install_curl_packages() {
    log_info "Processing Curl-based installers..."

    local CURL_LIST_FILE="$LISTS_DIR/curl.list"

    if [ ! -f "$CURL_LIST_FILE" ]; then
        log_warning "No curl.list found, skipping..."
        return
    fi

    local installed=0
    local skipped=0

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        log_info "Executing curl installer: $line"
        if eval "$line" 2>&1 | tee -a "$LOG_FILE"; then
            ((installed++))
            log_success "Curl installer completed"
        else
            log_error "Curl installer failed: $line"
        fi
    done < "$CURL_LIST_FILE"

    log_success "Processed $installed curl installers"
}

# ==============================================================================
# 5. RPM DIRECT DOWNLOADS
# ==============================================================================
install_rpm_packages() {
    log_info "Processing direct RPM downloads..."

    local RPM_LIST_FILE="$LISTS_DIR/rpm.list"

    if [ ! -f "$RPM_LIST_FILE" ]; then
        log_warning "No rpm.list found, skipping..."
        return
    fi

    local installed=0

    while IFS= read -r url; do
        # Skip comments and empty lines
        [[ "$url" =~ ^#.*$ ]] && continue
        [[ -z "$url" ]] && continue

        local rpm_file="/tmp/$(basename "$url")"

        log_info "Downloading RPM from: $url"
        if wget -q -O "$rpm_file" "$url"; then
            log_info "Installing downloaded RPM..."
            if sudo dnf install -y "$rpm_file" 2>&1 | tee -a "$LOG_FILE"; then
                ((installed++))
                log_success "RPM installed successfully"
            else
                log_error "Failed to install RPM"
            fi
            rm -f "$rpm_file"
        else
            log_error "Failed to download: $url"
        fi
    done < "$RPM_LIST_FILE"

    log_success "Installed $installed RPM packages"
}

# ==============================================================================
# 6. FONTS
# ==============================================================================
install_fonts() {
    log_info "Installing fonts..."

    local FONT_DIR="$HOME/.local/share/fonts"
    local FONT_NAME="JetBrainsMono"
    local FONT_VERSION="v3.4.0"
    local FONT_PATH="$FONT_DIR/$FONT_NAME"

    if [ -d "$FONT_PATH" ] && [ "$(ls -A "$FONT_PATH" 2>/dev/null)" ]; then
        log_success "Nerd Fonts ($FONT_NAME) already installed"
        return
    fi

    log_info "Installing Nerd Fonts ($FONT_NAME)..."
    mkdir -p "$FONT_PATH"

    local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/$FONT_VERSION/$FONT_NAME.zip"
    local TEMP_ZIP="/tmp/$FONT_NAME.zip"

    if wget -q --show-progress -O "$TEMP_ZIP" "$FONT_URL"; then
        if unzip -o -q "$TEMP_ZIP" -d "$FONT_PATH"; then
            rm -f "$TEMP_ZIP"
            fc-cache -fv > /dev/null 2>&1
            log_success "Nerd Fonts installed successfully"
        else
            log_error "Failed to extract fonts"
            rm -f "$TEMP_ZIP"
            return 1
        fi
    else
        log_error "Failed to download fonts"
        return 1
    fi
}

# ==============================================================================
# 7. EXTRAS / SPECIAL PACKAGES
# ==============================================================================
install_extras() {
    log_info "Installing extra packages..."

    # Virtualization
    if ! dnf group list --installed 2>/dev/null | grep -q "Virtualization"; then
        log_info "Installing Virtualization group..."
        sudo dnf group install -y "Virtualization" 2>&1 | tee -a "$LOG_FILE"
        sudo systemctl enable --now libvirtd &> /dev/null
        sudo usermod -aG libvirt "$USER" &> /dev/null
        log_success "Virtualization configured"
    else
        log_success "Virtualization already configured"
    fi

    # Cava (Audio Visualizer)
    if ! is_dnf_installed "cava"; then
        log_info "Installing Cava..."
        sudo dnf install -y cava 2>&1 | tee -a "$LOG_FILE" || log_warning "Cava not available in repositories"
    fi
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

log_info "=========================================="
log_info "  OhMyPanama Package Installation"
log_info "=========================================="

# Execute installation functions
install_dnf_packages
install_copr_packages
install_flatpak_packages
install_curl_packages
install_rpm_packages
install_fonts
install_extras

log_success "=========================================="
log_success "  Package Installation Complete!"
log_success "=========================================="
log_info "Log file: $LOG_FILE"
