#!/bin/bash

echo "[MODULE] Configuring System..."

# --- Zsh configs ---
if [ "$SHELL" != "/usr/bin/zsh" ] && [ -x "/usr/bin/zsh" ]; then
    echo "[+] Defining Zsh as default shell..."
    sudo chsh -s /usr/bin/zsh $USER
fi

# Installing Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[+] Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Configure Plugins .zshrc (Starship, Zoxide, Bat)
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
    # Starship
    if ! grep -q "starship init zsh" "$ZSHRC"; then
        echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
    fi
    # Zoxide
    if ! grep -q "zoxide init zsh" "$ZSHRC"; then
        echo 'eval "$(zoxide init zsh)"' >> "$ZSHRC"
    fi
    # Alias para Bat (replacing cat)
    if ! grep -q "alias cat='bat'" "$ZSHRC"; then
        echo "alias cat='bat'" >> "$ZSHRC"
    fi
    # Add Cargo bin to PATH in zshrc
    if ! grep -q "export PATH=\"\$HOME/.cargo/bin:\$PATH\"" "$ZSHRC"; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$ZSHRC"
    fi
fi

# --- Security: UFW---
if systemctl is-active firewalld; then
    echo "[+] Disable firewalld and enable UFW..."
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
fi

# UFW config
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Here i'm allowing ssh
sudo ufw allow ssh
sudo ufw enable
