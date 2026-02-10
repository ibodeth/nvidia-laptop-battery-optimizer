#!/bin/bash

# NVIDIA Power Optimizer Uninstaller
# Restores system to default state

RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}Starting Uninstallation...${NC}"

# 1. Remove Files and Rules
echo "Removing script and udev rules..."
sudo rm -f /usr/local/bin/gpu-optimizer.sh
sudo rm -f /etc/udev/rules.d/99-gpu-power.rules

# 2. Cleanup Legacy Denials (if any)
sudo rm -f /usr/local/bin/power-daemon.sh 2>/dev/null
sudo rm -f /etc/systemd/system/power-optimizer.service 2>/dev/null
sudo systemctl daemon-reload

# 3. Reset Hardware State
GPU_ID=$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader | head -n1)
if [ ! -z "$GPU_ID" ]; then
    echo "Resetting GPU clock limits to factory defaults..."
    sudo nvidia-smi -i $GPU_ID -rgc
fi

# 4. Refresh udev
echo "Refreshing udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

echo -e "${RED}Uninstallation complete. System restored.${NC}"
