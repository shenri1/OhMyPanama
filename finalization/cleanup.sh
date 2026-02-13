#!/bin/bash

# ==============================================================================
# OhMyPanama - Cleanup and Finalization Module
# Description: Cleans up installation artifacts and optimizes system
# Author: Silas Henrique
# ==============================================================================

set -e
set -o pipefail

LOG_FILE="$HOME/.local/state/ohmypanama/cleanup.log"

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

# ==============================================================================
# MAIN MODULE
# ==============================================================================
log_info "=========================================="
log_info "  Cleanup and Finalization Module"
log_info "=========================================="

mkdir -p "$(dirname "$LOG_FILE")"

# ==============================================================================
# 1. DNF CLEANUP
# ==============================================================================
cleanup_dnf() {
    log_info "Cleaning DNF cache and unused packages..."

    # Remove unused packages
    log_info "Removing unused packages (autoremove)..."
    if sudo dnf autoremove -y 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Unused packages removed"
    else
        log_warning "Some packages could not be removed"
    fi

    # Clean DNF cache
    log_info "Cleaning DNF cache..."
    if sudo dnf clean all 2>&1 | tee -a "$LOG_FILE"; then
        log_success "DNF cache cleaned"
    else
        log_warning "Failed to clean DNF cache"
    fi

    # Optional: Remove old kernels (keep last 2)
    local KERNEL_COUNT=$(rpm -q kernel | wc -l)
    if [ "$KERNEL_COUNT" -gt 2 ]; then
        log_info "Found $KERNEL_COUNT kernels installed"
        log_info "Removing old kernels (keeping latest 2)..."
        sudo dnf remove -y $(dnf repoquery --installonly --latest-limit=-2 -q) 2>&1 | tee -a "$LOG_FILE" || true
        log_success "Old kernels removed"
    else
        log_info "Kernel count: $KERNEL_COUNT (no cleanup needed)"
    fi
}

# ==============================================================================
# 2. FLATPAK CLEANUP
# ==============================================================================
cleanup_flatpak() {
    if command -v flatpak &> /dev/null; then
        log_info "Cleaning Flatpak cache..."

        # Remove unused runtimes and apps
        if flatpak uninstall --unused -y 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Unused Flatpak runtimes removed"
        else
            log_warning "No unused Flatpak runtimes found"
        fi

        # Repair Flatpak installation
        log_info "Repairing Flatpak installation..."
        flatpak repair --user 2>&1 | tee -a "$LOG_FILE" || true
    fi
}

# ==============================================================================
# 3. TEMPORARY FILES CLEANUP
# ==============================================================================
cleanup_temp_files() {
    log_info "Cleaning temporary files..."

    # Clean user cache
    if [ -d "$HOME/.cache" ]; then
        local CACHE_SIZE=$(du -sh "$HOME/.cache" 2>/dev/null | cut -f1)
        log_info "Current cache size: $CACHE_SIZE"

        # Remove old thumbnails
        find "$HOME/.cache/thumbnails" -type f -atime +30 -delete 2>/dev/null || true

        log_success "Cache cleaned"
    fi

    # Clean temporary downloads
    if [ -d "/tmp" ]; then
        log_info "Cleaning /tmp directory..."
        sudo find /tmp -type f -atime +7 -delete 2>/dev/null || true
    fi

    # Clean systemd journal logs (keep last 7 days)
    log_info "Cleaning old journal logs..."
    sudo journalctl --vacuum-time=7d 2>&1 | tee -a "$LOG_FILE" || true
}

# ==============================================================================
# 4. FONT CACHE REBUILD
# ==============================================================================
rebuild_font_cache() {
    log_info "Rebuilding font cache..."
    if fc-cache -fv > /dev/null 2>&1; then
        log_success "Font cache rebuilt"
    else
        log_warning "Failed to rebuild font cache"
    fi
}

# ==============================================================================
# 5. UPDATE DESKTOP DATABASE
# ==============================================================================
update_desktop_database() {
    log_info "Updating desktop database..."

    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        log_success "Desktop database updated"
    fi
}

# ==============================================================================
# 6. GENERATE INSTALLATION SUMMARY
# ==============================================================================
generate_summary() {
    log_info "Generating installation summary..."

    local SUMMARY_FILE="$HOME/.local/state/ohmypanama/summary.txt"

    cat > "$SUMMARY_FILE" << EOF
================================================================================
                    OhMyPanama Installation Summary
================================================================================

Installation Date: $(date)
User: $USER
Hostname: $(hostname)
OS: $(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)
Kernel: $(uname -r)

================================================================================
                            Installed Components
================================================================================

Shell Configuration:
  - Default Shell: $(basename "$SHELL")
  - Oh My Zsh: $([ -d "$HOME/.oh-my-zsh" ] && echo "✓ Installed" || echo "✗ Not Installed")
  - Starship: $(command -v starship &>/dev/null && echo "✓ Installed" || echo "✗ Not Installed")

Security:
  - Firewall: $(systemctl is-active ufw 2>/dev/null || echo "inactive")
  - UFW Status: $(sudo ufw status 2>/dev/null | head -1)

Package Counts:
  - DNF Packages: $(rpm -qa | wc -l)
  - Flatpak Apps: $(flatpak list --app 2>/dev/null | wc -l)

Disk Usage:
  - Home Directory: $(du -sh "$HOME" 2>/dev/null | cut -f1)
  - Cache Size: $(du -sh "$HOME/.cache" 2>/dev/null | cut -f1)

================================================================================
                               Next Steps
================================================================================

1. Logout and login again to apply shell changes
2. Reboot your system for all changes to take effect:
   sudo reboot

3. Optional: Configure Git credentials
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"

4. Optional: Customize Starship prompt
   Edit: ~/.config/starship.toml

5. Review logs at:
   ~/.local/state/ohmypanama/

================================================================================
                          Thank you for using OhMyPanama!
================================================================================

EOF

    log_success "Installation summary saved to: $SUMMARY_FILE"
    cat "$SUMMARY_FILE"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

cleanup_dnf
cleanup_flatpak
cleanup_temp_files
rebuild_font_cache
update_desktop_database
generate_summary

log_success "=========================================="
log_success "  Cleanup and Finalization Complete!"
log_success "=========================================="
log_info "All logs saved to: ~/.local/state/ohmypanama/"
