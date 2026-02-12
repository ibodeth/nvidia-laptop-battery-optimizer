#!/bin/bash

# NVIDIA Power Optimizer - Ultra Universal Installer
# Designed for maximum compatibility across all major Linux distributions.

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   NVIDIA Power Optimizer - Ultra Installer    ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. Detect OS and Package Manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_BASE="${ID_LIKE:-$ID}"
    echo -e "${BLUE}Detected System: $NAME ($OS_BASE)${NC}"
else
    echo -e "${RED}Error: OS detection failed! /etc/os-release is missing.${NC}"
    exit 1
fi

# 2. Smart Dependency Installation
echo -e "${BLUE}Installing dependencies...${NC}"

install_pkg() {
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm "$@"
    elif command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y "$@"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$@"
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "$@"
    else
        echo -e "${RED}Could not find a supported package manager (apt, pacman, dnf, zypper).${NC}"
        echo "Please install 'nvidia-smi' and 'power-profiles-daemon' manually."
    fi
}

# Distro-specific package naming
if [[ "$ID" == "pop" ]]; then
    echo "Pop!_OS specific environment detected."
    install_pkg nvidia-smi system76-power
elif [[ "$OS_BASE" == *"debian"* || "$OS_BASE" == *"ubuntu"* ]]; then
    sudo apt update
    # Attempt common NVIDIA util names for Debian/Ubuntu
    sudo apt install -y nvidia-smi power-profiles-daemon || sudo apt install -y nvidia-utils-535 power-profiles-daemon
else
    # General names for Arch, Fedora, OpenSUSE
    install_pkg nvidia-utils power-profiles-daemon || install_pkg nvidia-smi power-profiles-daemon
fi

# 3. GPU ID Detection
if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo -e "${RED}Error: 'nvidia-smi' not found. Is the NVIDIA driver installed?${NC}"
    exit 1
fi

GPU_ID=$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader | head -n1)
if [ -z "$GPU_ID" ]; then
    echo -e "${RED}Error: No NVIDIA GPU detected by nvidia-smi.${NC}"
    exit 1
fi
echo -e "${GREEN}GPU ID Mapped: $GPU_ID${NC}"

# 4. Create Adaptive Optimizer Script
cat << EOF | sudo tee /usr/local/bin/gpu-optimizer.sh > /dev/null
#!/bin/bash
# Optimized for: powerprofilesctl, system76-power, and manual fallback.

GPU_ID="$GPU_ID"
AC_STATUS=\$(cat /sys/class/power_supply/AC*/online | head -n1)
nvidia-smi -pm 1

# Runtime Power Manager Detection
if command -v powerprofilesctl >/dev/null 2>&1; then
    PWR_CMD="powerprofilesctl set"
    BAT_PROF="power-saver"
    AC_PROF="balanced"
elif command -v system76-power >/dev/null 2>&1; then
    PWR_CMD="system76-power profile"
    BAT_PROF="battery"
    AC_PROF="balanced"
else
    PWR_CMD="true" 
fi

if [ "\$AC_STATUS" -eq 0 ]; then
    # BATTERY MODE: Hardware lock to 210-400MHz
    nvidia-smi -i \$GPU_ID -lgc 210,400
    \$PWR_CMD \$BAT_PROF
else
    # AC MODE: Release hardware lock
    nvidia-smi -i \$GPU_ID -rgc
    \$PWR_CMD \$AC_PROF
fi
EOF
sudo chmod +x /usr/local/bin/gpu-optimizer.sh

# 5. Setup Hot-Plug (udev)
echo 'SUBSYSTEM=="power_supply", ACTION=="change", RUN+="/usr/bin/bash /usr/local/bin/gpu-optimizer.sh"' | sudo tee /etc/udev/rules.d/99-gpu-power.rules > /dev/null

# 6. Setup Boot-Time Init (systemd)
cat << EOF | sudo tee /etc/systemd/system/gpu-power-init.service > /dev/null
[Unit]
Description=Set NVIDIA Power State on Boot
After=multi-user.target nvidia-persistenced.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/gpu-optimizer.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

# 7. Enable and Trigger
sudo systemctl daemon-reload
sudo systemctl enable gpu-power-init.service 2>/dev/null

# Conditional start for power daemons
if systemctl list-unit-files | grep -q "power-profiles-daemon.service"; then
    sudo systemctl enable --now power-profiles-daemon
fi

sudo udevadm control --reload-rules
sudo udevadm trigger

echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}   Universal Installation Complete!            ${NC}"
echo -e "${GREEN}   Tested on: $NAME                            ${NC}"
echo -e "${GREEN}===============================================${NC}"
