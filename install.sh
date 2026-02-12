#!/bin/bash

# NVIDIA Power Optimizer - Universal Hybrid Setup
# Handles both Boot-time (systemd) and Hot-plug (udev) events.

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   NVIDIA Power Optimizer - Pro Installer      ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. Detect OS Base
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_BASE="${ID_LIKE:-$ID}"
    echo -e "${BLUE}System Base: $OS_BASE${NC}"
else
    echo -e "${RED}Error: OS detection failed!${NC}"
    exit 1
fi

# 2. Install Dependencies
case "$OS_BASE" in
    *arch*)
        sudo pacman -S --noconfirm nvidia-utils power-profiles-daemon
        ;;
    *debian*|*ubuntu*)
        sudo apt update && sudo apt install -y nvidia-utils-common power-profiles-daemon
        ;;
    *fedora*|*rhel*)
        sudo dnf install -y nvidia-smi power-profiles-daemon
        ;;
    *)
        echo -e "${RED}Please install nvidia-smi and power-profiles-daemon manually.${NC}"
        ;;
esac

# 3. Detect GPU ID
GPU_ID=$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader | head -n1)
if [ -z "$GPU_ID" ]; then
    echo -e "${RED}Error: NVIDIA GPU not found!${NC}"
    exit 1
fi

# 4. Create Core Script
cat << EOF | sudo tee /usr/local/bin/gpu-optimizer.sh > /dev/null
#!/bin/bash
GPU_ID="$GPU_ID"
AC_STATUS=\$(cat /sys/class/power_supply/AC*/online | head -n1)
nvidia-smi -pm 1

if [ "\$AC_STATUS" -eq 0 ]; then
    # BATTERY MODE
    nvidia-smi -i \$GPU_ID -lgc 210,400
    powerprofilesctl set power-saver
else
    # AC MODE
    nvidia-smi -i \$GPU_ID -rgc
    powerprofilesctl set balanced
fi
EOF
sudo chmod +x /usr/local/bin/gpu-optimizer.sh

# 5. Setup Hot-Plug (udev)
echo 'SUBSYSTEM=="power_supply", ACTION=="change", RUN+="/usr/bin/bash /usr/local/bin/gpu-optimizer.sh"' | sudo tee /etc/udev/rules.d/99-gpu-power.rules > /dev/null

# 6. Setup Boot-Time (systemd oneshot)
cat << EOF | sudo tee /etc/systemd/system/gpu-power-init.service > /dev/null
[Unit]
Description=Initialize NVIDIA Power State on Boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/gpu-optimizer.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

# 7. Activate Everything
sudo systemctl daemon-reload
sudo systemctl enable --now gpu-power-init.service
sudo systemctl enable --now power-profiles-daemon
sudo udevadm control --reload-rules
sudo udevadm trigger

echo -e "${GREEN}Done! System is now optimized for both boot and hot-plug events.${NC}"
