#!/bin/bash

set -e

# Verify the current OS version
if ! grep -q "Fedora" /etc/os-release; then
    echo "Unsupported OS version. Please use Fedora."
    exit 1
fi

# Verify the current user is root
if [ "$UID" -eq 0 ]; then
    cat <<EOF
Looks like you are running this script as root.

This is not recommended. Please run this script as a regular user with sudo privileges.

Press Enter to continue or Ctrl+C to exit.
EOF
    read input
fi

# Arguments Parser
NO_UNINSTALL=false
for arg in "$@"; do
    case $arg in
        --no-uninstall)
        NO_UNINSTALL=true;
        shift
        ;;
        *)
        # Unknown option
        ;;
    esac
done

if [ ! -f ~/.local/state/ohmypanama/installed ]; then
    clear
    cat <<EOF
Welcome to OhMyPanama!

OhMyPanama is a Linux Fedora flavor made by a passionate and new generation of devs.
This is a beta version and I am working hard to make it better.
We're combining the best tools and apps to give you an amazing experience out of the box.
Please consider leaving a feedback at the official repo.

Also, consider some advertisements:

- OhMyPanama is intended to be used on personal computers, specifically fresh new installations,
so for your safety, consider make a backup if you already have important data.
- This script will remove some apps like Firefox, DE games, and some default Fedora apps.
- This script will add some 3rd party repositories like RPM Fusion, VSCode, Brave Browser, and more.

Press Enter to continue or Ctrl+C to exit.
EOF

    read input

    # Confirm check to see if we have dnf installed and configure
    #TODO: Add check for dnf lock

    # TODO: Migrate this to a specific script later
    echo "Downloading and installing RPM Fusion repositories..."
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
          https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    # Initial update
    sudo dnf update -y
    sudo dnf install -y git

    # Create necessary directories
    mkdir -p ~/.local/state/ohmypanama
    mkdir -p ~/.config

    # Create installation marker
    touch ~/.local/state/ohmypanama/installed
    echo "$(date)" > ~/.local/state/ohmypanama/installed
fi

# Call ohmypanama.sh
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/ohmypanama.sh" "$@"