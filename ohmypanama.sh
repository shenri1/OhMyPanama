#!/bin/bash


# Check if the packages are already installed
if ! dpkg -s ohmypanama &> /dev/null 2>&1; then
    echo "OhMyPanama is not installed. Please run the install.sh script first."
    exit 1
fi


# Define base install dir
OHMYPANAMA_INSTALL=/usr/share/ohmypanama/install

#1. Packages Installations
source "$OHMYPANAMA_INSTALL/packages/packages.sh"

#2. System Configuration
source "$OHMYPANAMA_INSTALL/config/system.sh"

#3. Desktop Environment Configuration
source "$OHMYPANAMA_INSTALL/config/kde.sh"

#4. Finalization
source "$OHMYPANAMA_INSTALL/finalization/cleanup.sh"

# Maybe i need to delete this echos, i need to look up first
echo ""
echo "======================================================="
echo "                  OhMyPanama Installation Complete with Success!!                         "
echo "                       Please, reboot your system to apply changes.                               "
echo "                  Also, consider leaving a review on GitHub or sharing                        "
echo "                                  your experience on social media.                                            "
echo "======================================================="
echo ""
