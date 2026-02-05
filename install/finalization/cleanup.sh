#!/bin/bash

echo "[MODULE] Cleanup and Finalization..."

# Remove unused packages and clean cache
sudo dnf autoremove -y
sudo dnf clean all

echo ""
echo "NOTE: 'kdotool' was installed in ~/.cargo/bin/kdotool."
echo "Update your scripts that use 'xdotool' to use 'kdotool'."
