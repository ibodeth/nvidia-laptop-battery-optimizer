#!/bin/bash

# NVIDIA Power Optimizer - Ultra Universal Installer
# Tüm ana akım Linux dağıtımları için maksimum uyumlulukla tasarlanmıştır.

# Çıktı renkleri
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # Renk yok

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   NVIDIA Power Optimizer - Ultra Installer    ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. İşletim Sistemi ve Paket Yöneticisi Tespiti
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_BASE="${ID_LIKE:-$ID}"
    echo -e "${BLUE}Tespit Edilen Sistem: $NAME ($OS_BASE)${NC}"
else
    echo -e "${RED}Hata: Sistem tespiti başarısız! /etc/os-release dosyası bulunamadı.${NC}"
    exit 1
fi

# 2. Akıllı Bağımlılık Kurulumu
echo -e "${BLUE}Bağımlılıklar kuruluyor...${NC}"

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
        echo -e "${RED}Desteklenen bir paket yöneticisi bulunamadı (apt, pacman, dnf, zypper).${NC}"
        echo "Lütfen 'nvidia-smi' ve 'power-profiles-daemon' paketlerini manuel kurun."
    fi
}

# Dağıtıma özel paket isimlendirmeleri
if [[ "$ID" == "pop" ]]; then
    echo "Pop!_OS özel ortamı algılandı."
    install_pkg nvidia-smi system76-power
elif [[ "$OS_BASE" == *"debian"* || "$OS_BASE" == *"ubuntu"* ]]; then
    sudo apt update
    # Debian/Ubuntu için yaygın NVIDIA araç isimlerini dene
    sudo apt install -y nvidia-smi power-profiles-daemon || sudo apt install -y nvidia-utils-535 power-profiles-daemon
else
    # Arch, Fedora, OpenSUSE için genel isimler
    install_pkg nvidia-utils power-profiles-daemon || install_pkg nvidia-smi power-profiles-daemon
fi

# 3. GPU ID Tespiti
if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo -e "${RED}Hata: 'nvidia-smi' bulunamadı. NVIDIA sürücüsü kurulu mu?${NC}"
    exit 1
fi

GPU_ID=$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader | head -n1)
if [ -z "$GPU_ID" ]; then
    echo -e "${RED}Hata: nvidia-smi tarafından herhangi bir NVIDIA GPU tespit edilemedi.${NC}"
    exit 1
fi
echo -e "${GREEN}GPU ID Eşlendi: $GPU_ID${NC}"

# 4. Adaptif Optimizer Scriptini Oluştur
# Bu script powerprofilesctl ve system76-power'ı çalışma anında tespit eder.
cat << EOF | sudo tee /usr/local/bin/gpu-optimizer.sh > /dev/null
#!/bin/bash

GPU_ID="$GPU_ID"
AC_STATUS=\$(cat /sys/class/power_supply/AC*/online | head -n1)
nvidia-smi -pm 1

# Çalışma Anında Güç Yöneticisi Tespiti
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
    # PİL MODU: Donanımsal olarak 210-400MHz arasına kilitle
    nvidia-smi -i \$GPU_ID -lgc 210,400
    \$PWR_CMD \$BAT_PROF
else
    # PRİZ MODU: Donanımsal kilidi kaldır
    nvidia-smi -i \$GPU_ID -rgc
    \$PWR_CMD \$AC_PROF
fi
EOF
sudo chmod +x /usr/local/bin/gpu-optimizer.sh

# 5. Hot-Plug Ayarı (udev)
echo 'SUBSYSTEM=="power_supply", ACTION=="change", RUN+="/usr/bin/bash /usr/local/bin/gpu-optimizer.sh"' | sudo tee /etc/udev/rules.d/99-gpu-power.rules > /dev/null

# 6. Başlangıç Ayarı (systemd oneshot)
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

# 7. Etkinleştir ve Tetikle
sudo systemctl daemon-reload
sudo systemctl enable gpu-power-init.service 2>/dev/null

# Güç yöneticisi servisleri için koşullu başlatma
if systemctl list-unit-files | grep -q "power-profiles-daemon.service"; then
    sudo systemctl enable --now power-profiles-daemon
fi

sudo udevadm control --reload-rules
sudo udevadm trigger

echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}   Evrensel Kurulum Tamamlandı!                ${NC}"
echo -e "${GREEN}   Test Edilen Sistem: $NAME                    ${NC}"
echo -e "${GREEN}===============================================${NC}"
