NVIDIA Power Optimizer (Event-Based) 🚀

An automated, lightweight, and event-driven power management solution for NVIDIA-powered laptops on Linux.

⚠️ The "No-iGPU" Life Saver

Many high-end gaming laptops either lack an iGPU (Integrated Graphics) or are used in Discrete GPU Only (MUX Switch / Dedicated Mode). On Linux, this is often a recipe for disaster: the NVIDIA GPU runs at high clock speeds even for simple desktop tasks, causing high temperatures and abysmal battery life.

This tool is essential for these setups. It mimics a "Low Power Mode" for your dedicated GPU by forcing it into a 210-400MHz clock range the moment you unplug your charger, effectively extending battery life and keeping your lap cool.

✨ Features

Zero Idle Overhead: Not a daemon. It consumes 0% CPU/RAM. It is only triggered by hardware udev events when power state changes.

Dynamic Clock Locking: Uses nvidia-smi -lgc to hardware-lock clocks on battery and nvidia-smi -rgc to release them on AC.

Integrated System Profiles: Seamlessly switches CPU energy profiles via power-profiles-daemon.

Universal Distro Support: Intelligent installer detects your base (Arch, Debian/Ubuntu, Fedora) and handles dependencies.

Auto-Detect: Zero configuration needed; detects your specific GPU Bus ID during installation.

🛠️ Requirements

NVIDIA GPU: RTX 20, 30, 40 or GTX 16 series (Maxwell/Pascal might work but -lgc support varies).

Drivers: Proprietary NVIDIA Drivers (Open-source nouveau is NOT supported).

Distro: Any major Linux distribution with udev and systemd.

🚀 Installation

Clone the repository and run the installer:

git clone [https://github.com/YOUR_USERNAME/nvidia-pwr-optimizer.git](https://github.com/YOUR_USERNAME/nvidia-pwr-optimizer.git)
cd nvidia-pwr-optimizer
chmod +x install.sh uninstall.sh
sudo ./install.sh


🗑️ Uninstallation

To remove all files and reset your GPU to factory clock settings:

sudo ./uninstall.sh


🔍 How It Works

The system leverages the Linux Kernel's udev subsystem to monitor the power supply.

Unplugging (Battery): udev triggers the optimizer which sends a hardware lock command to the GPU: nvidia-smi -lgc 210,400.

Plugging In (AC): udev triggers a reset command: nvidia-smi -rgc, allowing the GPU to boost to its maximum potential.

🤝 Contributing

Contributions are welcome! If you have a fix for specific laptop models or additional power-saving tips, feel free to open a PR.

Developed by ibo
AI Operations Student & Linux Enthusiast
