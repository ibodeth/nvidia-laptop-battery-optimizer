#!/bin/bash

RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}Uninstalling NVIDIA Power Optimizer...${NC}"

# Stop and Disable Service
sudo systemctl disable --now gpu-power-init.service 2>/dev/null
sudo rm -f /etc/systemd/system/gpu-power-init.service

# Remove Files
sudo rm -f /usr/local/bin/gpu-optimizer.sh
sudo rm -f /etc/udev/rules.d/99-gpu-power.rules

# Reset GPU
GPU_ID=$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader | head -n1)
if [ ! -z "$GPU_ID" ]; then
    sudo nvidia-smi -i $GPU_ID -rgc
fi

# Refresh System
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo udevadm trigger

echo -e "${RED}Uninstallation complete.${NC}"
