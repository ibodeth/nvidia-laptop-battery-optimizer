# NVIDIA Laptop Battery Optimizer

An event-driven power management utility for NVIDIA GPUs on Linux laptops.

## How it Works
The utility uses the Linux udev subsystem to listen to power insertion and removal events (charger plugged or unplugged). When unplugged, a script executes `nvidia-smi` to lock the GPU clocks to a low range (210-400 MHz) and triggers the CPU energy profile to switch via the power-profiles-daemon, reducing power draw. When plugged in, default clock behavior and power profiles are restored.

## Tech Stack
- **Languages/Frameworks:** Bash
- **Services/Libraries:** udev, nvidia-smi, power-profiles-daemon
- **Infrastructure:** Linux systemd

## Local Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/ibodeth/nvidia-laptop-battery-optimizer.git
   cd nvidia-laptop-battery-optimizer
   ```
2. Make scripts executable and run the installer:
   ```bash
   chmod +x install.sh uninstall.sh
   sudo ./install.sh
   ```
3. To uninstall the utility:
   ```bash
   sudo ./uninstall.sh
   ```

## License
MIT
