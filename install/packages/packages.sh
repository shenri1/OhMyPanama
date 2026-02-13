#!/bin/bash

LISTS_DIR="$(dirname "$(readlink -f "$0")")/lists"

echo "[MODULE] Package Management Module Initialized..."

# ==============================================================================
# AUX FUNC: Read List (remove comments and empty lines)
# ==============================================================================
read_list() {
    [ -f "$1" ] && grep -vE '^\s*#|^\s*$' "$1"
}

# ==============================================================================
# 1. DNF (Fedora Native)
# ==============================================================================
echo "[+] Checking DNF packages..."
DNF_LIST=$(read_list "$LISTS_DIR/dnf.list")
TO_INSTALL=""

for pkg in $DNF_LIST; do
    if ! rpm -q "$pkg" &> /dev/null; then
        echo "   [>>] Queued: $pkg"
        TO_INSTALL="$TO_INSTALL $pkg"
    fi
done

if [ -n "$TO_INSTALL" ]; then
    echo "[+] Installing queued DNF packages..."
    sudo dnf install -y $TO_INSTALL
else
    echo "   [OK] DNF packages up to date."
fi

# ==============================================================================
# 1.1 DNF Copr (Fedora Native)
# ==============================================================================

echo "[+] Processing COPR Repositories..."
COPR_LIST_FILE="$LISTS_DIR/copr.list"

if [ -f "$COPR_LIST_FILE" ]; then
    # Install DNF's plugin core
    sudo dnf install -y dnf-plugins-core

    while IFS='|' read -r repo_id packages; do
        [[ "$repo_id" =~ ^#.*$ ]] && continue
        [[ -z "$repo_id" ]] && continue

        repo_id=$(echo "$repo_id" | xargs)
        packages=$(echo "$packages" | xargs)

        echo "   [+] Enabling COPR repo: $repo_id"
        sudo dnf copr enable -y "$repo_id"

        if [ -n "$packages" ]; then
             echo "   [+] Installing packages from $repo_id: $packages"
             sudo dnf install -y $packages
        fi
    done < "$COPR_LIST_FILE"
fi

# ==============================================================================
# 2. FLATPAK (Universal)
# ==============================================================================
echo "[+] Checking Flatpaks..."
if ! command -v flatpak &> /dev/null; then
    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

FLATPAK_LIST=$(read_list "$LISTS_DIR/flatpak.list")
for app in $FLATPAK_LIST; do
    if ! flatpak list --app | grep -q "$app"; then
        echo "   [+] Installing Flatpak: $app"
        flatpak install -y flathub "$app"
    fi
done

# ==============================================================================
# 3. CURL INSTALLERS (Scripts Web)
# ==============================================================================
echo "[+] Processing Curl Installers..."
CURL_LIST_FILE="$LISTS_DIR/curl.list"

if [ -f "$CURL_LIST_FILE" ]; then
    while IFS='|' read -r pkg_name check_cmd url install_cmd; do
        [[ "$pkg_name" =~ ^#.*$ ]] && continue
        [[ -z "$pkg_name" ]] && continue

        pkg_name=$(echo "$pkg_name" | xargs)
        check_cmd=$(echo "$check_cmd" | xargs)
        url=$(echo "$url" | xargs)
        install_cmd=$(echo "$install_cmd" | xargs)

        if eval "$check_cmd" &> /dev/null; then
            echo "   [OK] $pkg_name already installed."
        else
            echo "   [+] Installing $pkg_name via Curl..."
            curl -fsSL "$url" | $install_cmd
        fi
    done < "$CURL_LIST_FILE"
else
    echo "   [INFO] No curl.list found."
fi

# ==============================================================================
# 4. CARGO (Rust) OBS: Now it's not available. 
# ==============================================================================
# echo "[+] Checking Cargo crates..."
# if command -v cargo &> /dev/null; then
#     # Adiciona cargo ao PATH temporariamente
#     export PATH="$HOME/.cargo/bin:$PATH"
#     CARGO_LIST=$(read_list "$LISTS_DIR/cargo.list")
#     for crate in $CARGO_LIST; do
#         if ! command -v "$crate" &> /dev/null; then
#             echo "   [+] Installing crate: $crate"
#             cargo install "$crate"
#         fi
#     done
# fi

# ==============================================================================
# 5. PIP (Python) OBS: Now it's not available. 
# ==============================================================================
# echo "[+] Processing Python (Pip) Packages..."
# PIP_LIST=$(read_list "$LISTS_DIR/pip.list")

# if [ -n "$PIP_LIST" ]; then
#     for pip_pkg in $PIP_LIST; do
#         if ! python3 -m pip show "$pip_pkg" &> /dev/null; then
#             echo "   [+] Installing Pip package: $pip_pkg"
#             python3 -m pip install "$pip_pkg" --break-system-packages
#         else
#             echo "   [OK] $pip_pkg already installed."
#         fi
#     done
# fi

# ==============================================================================
# 6. FONTS
# ==============================================================================
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -d "$FONT_DIR/JetBrainsMono" ]; then
    echo "[+] Installing Nerd Fonts (JetBrainsMono)..."
    mkdir -p "$FONT_DIR/JetBrainsMono"
    # Baixa apenas a JetBrainsMono Nerd Font (robusta e compatível)
    wget -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
    unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR/JetBrainsMono"
    rm /tmp/JetBrainsMono.zip
    fc-cache -fv
fi

# ==============================================================================
# 7. EXTRAS / MANUALS
# ==============================================================================
echo "[+] Processing Extras..."

# Cava (Visualizer)
if ! rpm -q cava &> /dev/null; then
    echo "   [+] Installing Cava..."
    sudo dnf install -y cava || echo "   [!] Cava not in repo, skipping."
fi

# Virtualization
echo "   [+] Ensuring Virtualization Group..."
sudo dnf install -y @virtualization
sudo systemctl enable --now libvirtd &> /dev/null
sudo usermod -aG libvirt $USER &> /dev/null

echo "[MODULE] Packages module finished."
