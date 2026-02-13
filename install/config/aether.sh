#!/bin/bash

echo "[MODULE] Installing Aether (Theme Manager)..."

# 1. Instalar Dependências no Fedora
# O Aether precisa de GJS (Gnome JavaScript), GTK4 e LibAdwaita para rodar.
DEPS="gjs gtk4 libadwaita libsoup3 ImageMagick"
echo "   [+] Installing Aether dependencies: $DEPS"
sudo dnf install -y $DEPS

# 2. Definir local de instalação
INSTALL_DIR="$HOME/.local/share/aether-app"
BIN_DIR="$HOME/.local/bin"

# 3. Clonar ou Atualizar o Aether
if [ -d "$INSTALL_DIR" ]; then
    echo "   [+] Updating Aether..."
    cd "$INSTALL_DIR" && git pull
else
    echo "   [+] Cloning Aether repository..."
    git clone https://github.com/bjarneo/aether.git "$INSTALL_DIR"
fi

# 4. Criar o executável (Symlink/Wrapper)
# O Aether roda via 'gjs -m src/main.js'
echo "   [+] Creating executable wrapper..."
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/aether" <<EOF
#!/bin/bash
cd "$INSTALL_DIR" || exit
exec gjs -m src/main.js "\$@"
EOF

chmod +x "$BIN_DIR/aether"

# 5. Adicionar ao PATH se não estiver
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# 6. Preparar estrutura de pastas do Aether (Standalone)
mkdir -p ~/.config/aether/custom
mkdir -p ~/.config/aether/themes

echo "   [OK] Aether installed. Run 'aether' to start."