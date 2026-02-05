#!/bin/bash

# Define base install dir
OHMYPANAMA_INSTALL="$(dirname "$(readlink -f "$0")")/install"

echo "[*] Initializing OhMyPanama Installation Modules..."

#1. Packages Installations
source "$OHMYPANAMA_INSTALL/packages/packages.sh"

#2. System Configuration
source "$OHMYPANAMA_INSTALL/config/system.sh"

#3. Desktop Environment Configuration
source "$OHMYPANAMA_INSTALL/config/kde.sh"

#4. Finalization
source "$OHMYPANAMA_INSTALL/finalization/cleanup.sh"


echo ""
echo "======================================================="
echo "                  OhMyPanama Installation Complete with Success!!                         "
echo "                       Please, reboot your system to apply changes.                               "
echo "                  Also, consider leaving a review on GitHub or sharing                        "
echo "                                  your experience on social media.                                            "
echo "======================================================="
echo ""
