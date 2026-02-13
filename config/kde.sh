#!/bin/bash

# ==============================================================================
# OhMyPanama - KDE Configuration Module
# Description: Configures KDE Plasma desktop environment
# Author: Silas Henrique
# ==============================================================================

set -e
set -o pipefail

LOG_FILE="$HOME/.local/state/ohmypanama/kde.log"

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
is_kde_running() {
    [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ]
}

kwriteconfig_exists() {
    command -v kwriteconfig5 &> /dev/null || command -v kwriteconfig6 &> /dev/null
}

get_kwriteconfig() {
    if command -v kwriteconfig6 &> /dev/null; then
        echo "kwriteconfig6"
    elif command -v kwriteconfig5 &> /dev/null; then
        echo "kwriteconfig5"
    else
        echo ""
    fi
}

# ==============================================================================
# MAIN MODULE
# ==============================================================================
log_info "=========================================="
log_info "  KDE Plasma Configuration Module"
log_info "=========================================="

mkdir -p "$(dirname "$LOG_FILE")"

# Check if KDE is available
if ! is_kde_running; then
    log_warning "KDE Plasma is not the current desktop environment"
    log_warning "Some configurations may not apply correctly"
    log_info "Current desktop: ${XDG_CURRENT_DESKTOP:-Unknown}"
fi

# ==============================================================================
# 1. KDE PACKAGES
# ==============================================================================
install_kde_packages() {
    log_info "Installing KDE-specific packages..."

    local KDE_PACKAGES=(
        "kate"                    # Advanced text editor
        "konsole"                 # Terminal emulator
        "dolphin-plugins"         # Additional Dolphin plugins
        "kde-connect"             # Phone integration
        "kcolorchooser"           # Color picker
        "spectacle"               # Screenshot tool
        "kcharselect"             # Character selector
        "krdc"                    # Remote desktop client
        "krfb"                    # Desktop sharing
    )

    local to_install=""

    for pkg in "${KDE_PACKAGES[@]}"; do
        if ! rpm -q "$pkg" &> /dev/null; then
            to_install="$to_install $pkg"
        fi
    done

    if [ -n "$to_install" ]; then
        log_info "Installing KDE packages:$to_install"
        sudo dnf install -y $to_install 2>&1 | tee -a "$LOG_FILE"
        log_success "KDE packages installed"
    else
        log_success "All KDE packages already installed"
    fi
}

# ==============================================================================
# 2. KONSOLE CONFIGURATION
# ==============================================================================
configure_konsole() {
    log_info "Configuring Konsole..."

    local KONSOLE_DIR="$HOME/.local/share/konsole"
    mkdir -p "$KONSOLE_DIR"

    # Create OhMyPanama profile
    local PROFILE_FILE="$KONSOLE_DIR/OhMyPanama.profile"

    cat > "$PROFILE_FILE" << 'EOF'
[Appearance]
ColorScheme=Breeze
Font=JetBrainsMono Nerd Font,12,-1,5,50,0,0,0,0,0

[General]
Name=OhMyPanama
Parent=FALLBACK/

[Scrolling]
HistorySize=10000

[Terminal Features]
BlinkingCursorEnabled=true
EOF

    log_success "Konsole profile created: OhMyPanama"
}

# ==============================================================================
# 3. PLASMA SETTINGS
# ==============================================================================
configure_plasma_settings() {
    log_info "Configuring Plasma settings..."

    local KWRITE=$(get_kwriteconfig)

    if [ -z "$KWRITE" ]; then
        log_warning "kwriteconfig not found, skipping Plasma configuration"
        return
    fi

    # Desktop Effects
    log_info "Configuring desktop effects..."
    $KWRITE --file kwinrc --group Compositing --key Enabled true
    $KWRITE --file kwinrc --group Compositing --key GLCore true

    # Touchpad configuration (if applicable)
    log_info "Configuring touchpad..."
    $KWRITE --file touchpadxlibinputrc --group "Touchpad" --key TapToClick true
    $KWRITE --file touchpadxlibinputrc --group "Touchpad" --key NaturalScroll true

    # Dolphin settings
    log_info "Configuring Dolphin..."
    $KWRITE --file dolphinrc --group General --key ShowFullPath true
    $KWRITE --file dolphinrc --group General --key RememberOpenedTabs true

    # Kate settings
    log_info "Configuring Kate..."
    $KWRITE --file katerc --group "KTextEditor Document" --key "Show Tabs" true
    $KWRITE --file katerc --group "KTextEditor View" --key "Line Numbers" true

    log_success "Plasma settings configured"
}

# ==============================================================================
# 4. KVANTUM THEME ENGINE (OPTIONAL)
# ==============================================================================
install_kvantum() {
    log_info "Checking Kvantum theme engine..."

    if ! rpm -q kvantum &> /dev/null; then
        log_info "Installing Kvantum..."
        sudo dnf install -y kvantum 2>&1 | tee -a "$LOG_FILE"
        log_success "Kvantum installed"
    else
        log_success "Kvantum already installed"
    fi
}

# ==============================================================================
# 5. PLASMA WIDGETS
# ==============================================================================
install_plasma_widgets() {
    log_info "Installing useful Plasma widgets..."

    local WIDGETS=(
        "plasma-systemmonitor"
        "plasma-nm"              # Network management
        "plasma-pa"              # Audio control
        "powerdevil"             # Power management
    )

    local to_install=""

    for widget in "${WIDGETS[@]}"; do
        if ! rpm -q "$widget" &> /dev/null; then
            to_install="$to_install $widget"
        fi
    done

    if [ -n "$to_install" ]; then
        log_info "Installing widgets:$to_install"
        sudo dnf install -y $to_install 2>&1 | tee -a "$LOG_FILE"
        log_success "Plasma widgets installed"
    else
        log_success "All widgets already installed"
    fi
}

# ==============================================================================
# 6. RESTART PLASMA (OPTIONAL)
# ==============================================================================
restart_plasma_notice() {
    log_info "=========================================="
    log_info "To apply all KDE changes, you can:"
    log_info "  1. Logout and login again (recommended)"
    log_info "  2. Restart Plasma Shell with:"
    log_info "     kquitapp5 plasmashell && kstart5 plasmashell"
    log_info "  3. Reboot your system"
    log_info "=========================================="
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

# Only run if on Fedora KDE Spin or KDE installed
if ! rpm -q plasma-workspace &> /dev/null; then
    log_warning "KDE Plasma workspace not detected"
    log_warning "Skipping KDE-specific configurations"
    log_info "This module is designed for Fedora KDE Spin"
    exit 0
fi

install_kde_packages
configure_konsole
configure_plasma_settings
install_kvantum
install_plasma_widgets
restart_plasma_notice

log_success "=========================================="
log_success "  KDE Configuration Complete!"
log_success "=========================================="
log_info "Log file: $LOG_FILE"
