#!/bin/bash

echo "[MODULE] Cleanup and Finalization..."

# Remove unused packages and clean cache
sudo dnf autoremove -y
sudo dnf clean all
