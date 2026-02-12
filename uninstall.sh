#!/bin/bash

# NVIDIA Power Optimizer - Ultra Universal Uninstaller
# Safely restores the system to its original state.

RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}===============================================${NC}"
echo -e "${RED}   NVIDIA Power Optimizer - Uninstaller        ${NC}"
echo -e "${RED}===============================================${NC}"

# 1. Stop and Disable the Boot Service
echo "Stopping and disabling the boot initialization service..."
sudo systemctl disable --now gpu-power-init.service 2>/dev/null
sudo rm -f /etc/systemd/system/gpu-power-init.service

# 2. Remove Scripts and Rules
echo "Removing optimizer script and udev rules..."
sudo rm -f /usr/local/bin/gpu-optimizer.sh
sudo rm -f /etc/udev/rules.d/99-gpu-power.rules

# 3. Reset Hardware State (Clock Limits)
# We detect the GPU ID again to ensure we reset the correct device
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_ID=$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader | head -n1)
    if [ ! -z "$GPU_ID" ]; then
        echo "Resetting GPU clock limits for $GPU_ID to factory defaults..."
        sudo nvidia-smi -i $GPU_ID -rgc
        # Optional: Disable persistence mode if you don't need it
        # sudo nvidia-smi -pm 0
    fi
else
    echo "nvidia-smi not found. Skipping hardware reset."
fi

# 4. Refresh System Configuration
echo "Reloading systemd and udev configurations..."
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo udevadm trigger

echo -e "${RED}===============================================${NC}"
echo -e "${RED}   Uninstallation Complete!                    ${NC}"
echo -e "${RED}   Your system is restored to defaults.        ${NC}"
echo -e "${RED}===============================================${NC}"
