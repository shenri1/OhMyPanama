#!/bin/bash

echo "[MODULE] Configuring KDE Plasma..."

# --- 1. Virtual Desktops (Workspaces) ---
echo "   [+] Setting up Workspaces: Trabalho, Pesquisa, Lazer..."

# Define o número de desktops para 3
kwriteconfig6 --file kwinrc --group Desktops --key Number 3
kwriteconfig6 --file kwinrc --group Desktops --key Rows 1

# Nomeia cada um
kwriteconfig6 --file kwinrc --group Desktops --key Name_1 "Trabalho"
kwriteconfig6 --file kwinrc --group Desktops --key Name_2 "Pesquisa"
kwriteconfig6 --file kwinrc --group Desktops --key Name_3 "Lazer"

# --- 2. Configurações Gerais ---
# Tema Dark (Padrão inicial)
kwriteconfig6 --file kdeglobals --group General --key ColorScheme "BreezeDark"

# Velocidade das Animações
kwriteconfig6 --file kwinrc --group Compositing --key AnimationSpeed 3

# Single Click
kwriteconfig6 --file kdeglobals --group KDE --key SingleClick true

# --- 3. Recarregar KWin ---
if command -v qdbus6 &> /dev/null; then
    qdbus6 org.kde.KWin /KWin reconfigure
fi

echo "   [OK] KDE configured."