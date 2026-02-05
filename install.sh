#!/bin/bash

set -e

# Verify the current OS version
if ! grep -q "Fedora" /etc/os-release; then
    echo "Unsupported OS version. Please use Fedora."
    exit 1
fi

# Verify the current user is root
if [ "$UID" -eq 0 ]; then
    echo "It appears you are running as root. Please run as a regular user."
    exit 1
fi

# Arguments Parser
NO_UNINSTALL=false
for arg in "$@"; do
    case $arg in
        --no-uninstall) NO_UNINSTALL=true; shift;;
    esac
done

if [ ! -f ~/.local/state/ohmypanama ]; then
    clear
    cat <<EOF
Welcome to OhMyPanama!

OhMyPanama is a Linux Fedora flavor made by a passionate and new generation of this OS community.
This is a beta version and I am working hard to make it better. Please consider leaving a feedback at the official repo.
Press Enter to continue or Ctrl+C to exit.
EOF

read input

    echo "Downloading and installing RPM Fusion repositories..."
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
          https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
          
    # VSCode repo
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    
    #Brave Browser repo
    if ! command -v brave-browser &> /dev/null; then
        sudo dnf install -y curl
        curl -fsS https://dl.brave.com/install.sh | sudo sh
    fi
    
    # Initial update
      sudo dnf update -y
      sudo dnf install -y git
      
      mkdir -p ~/.local/state/ohmypanama
      mkdir -p ~/.config
    
    # Call ohmyfedora.sh
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
    source "$SCRIPT_DIR/ohmypanama.sh" "$@"
