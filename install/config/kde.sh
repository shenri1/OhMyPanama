#!/bin/bash

echo "[MODULE] Configuring KDE Plasma..."

# --- Theme config (TODO: Right now is BreezeDark just to test, need to implement a better solution) ---
kwriteconfig6 --file kdeglobals --group General --key ColorScheme "BreezeDark"

# --- Performance (Animations) ---
kwriteconfig6 --file kwinrc --group Compositing --key AnimationSpeed 2

# --- Reload KWin ---
if command -v qdbus6 &> /dev/null; then
    qdbus6 org.kde.KWin /KWin reconfigure
elif command -v qdbus &> /dev/null; then
    qdbus org.kde.KWin /KWin reconfigure
fi

echo "[+] KDE Plasma configured."
