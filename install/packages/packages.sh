#!/bin/bash

echo "[MODULE] Installing packages and tools.."

# --- Packages via DNF ---
# NOTE: util-linux-user is reponsible for the chsh command, make sure it's installed
# I included 'brave-browser' just to make sure it's installed and updated
PKGS_DNF="
    zsh util-linux-user git wget
    alacritty rofi-wayland
    btop ufw apparmor-utils
    brave-browser
    keepassxc gimp ristretto
    neovim gedit code
    libreoffice-kf6
    rust cargo gcc
    bat zoxide eza
    python3-pip
"

echo "[+] Installing packages via DNF..."
sudo dnf install -y $PKGS_DNF

# --- Cava (Audio Visualizer) ---
echo "[+] Installing Cava..."
sudo dnf install -y cava || echo "ERROR: Cava not found in default repo, try compiling manually if necessary."

# --- kdotool ( KDE Wayland) ---
if ! command -v kdotool &> /dev/null; then
    echo "[+] Compiling and installing kdotool (via Cargo)..."
    cargo install kdotool

    # Add ~/.cargo/bin to PATH
    if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
else
    echo "[+] kdotool Already Installed."
fi

# --- Terminal Text Effects (tte) ---
echo "[+] Instaling Terminal Text Effects..."
pip install terminal-text-effects --break-system-packages

# --- Starship (Prompt) ---
if ! command -v starship &> /dev/null; then
    echo "[+] Instaling Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# --- Virtualização (KVM/QEMU) ---
echo "[+] Configuring Virtualização..."
sudo dnf install -y @virtualization
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
