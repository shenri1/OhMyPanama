#!/bin/bash

# Check if the installation marker exists
if [ ! -f ~/.local/state/ohmypanama/installed ]; then
    echo "OhMyPanama is not installed. Please run the install.sh script first."
    exit 1
fi

# Define base install dir (current directory for development, will be /usr/share/ohmypanama for system install)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
OHMYPANAMA_INSTALL="$SCRIPT_DIR/install"

# Verify install directory exists
if [ ! -d "$OHMYPANAMA_INSTALL" ]; then
    echo "Error: Installation directory not found at $OHMYPANAMA_INSTALL"
    exit 1
fi

echo "======================================================="
echo "          OhMyPanama Configuration Starting            "
echo "======================================================="
echo ""

#1. Packages Installations
if [ -f "$OHMYPANAMA_INSTALL/packages/packages.sh" ]; then
    source "$OHMYPANAMA_INSTALL/packages/packages.sh"
else
    echo "Warning: packages.sh not found, skipping..."
fi

#2. System Configuration
if [ -f "$OHMYPANAMA_INSTALL/config/system.sh" ]; then
    source "$OHMYPANAMA_INSTALL/config/system.sh"
else
    echo "Warning: system.sh not found, skipping..."
fi

#3. Desktop Environment Configuration
if [ -f "$OHMYPANAMA_INSTALL/config/kde.sh" ]; then
    source "$OHMYPANAMA_INSTALL/config/kde.sh"
else
    echo "Warning: kde.sh not found, skipping..."
fi

#4. Finalization
if [ -f "$OHMYPANAMA_INSTALL/finalization/cleanup.sh" ]; then
    source "$OHMYPANAMA_INSTALL/finalization/cleanup.sh"
else
    echo "Warning: cleanup.sh not found, skipping..."
fi

echo ""
echo "======================================================="
echo "     OhMyPanama Installation Complete with Success!!   "
echo "    Please, reboot your system to apply changes.       "
echo "   Also, consider leaving a review on GitHub or        "
echo "      sharing your experience on social media.         "
echo "======================================================="
echo ""
