# NVIDIA Laptop Battery Optimizer 🚀

An automated, lightweight, and **event-driven power management solution** for NVIDIA-powered laptops running Linux.

---

## ⚠️ The “No-iGPU” Life Saver

Many high-end gaming laptops either **lack an iGPU** or are used in **Discrete GPU Only** mode (MUX Switch / Dedicated Mode). On Linux, this often leads to the NVIDIA GPU running at unnecessarily high clock speeds even during basic desktop usage — resulting in:

* 🔥 High temperatures
* 🔋 Terrible battery life
* 🥵 An uncomfortably hot laptop

This project acts as a **Low Power Mode for NVIDIA dGPUs** by automatically forcing low GPU clocks the moment you unplug your charger — and restoring full performance when you plug it back in.

---

## ✨ Features

* **Zero Idle Overhead**
  No daemon, no polling. Uses `udev` events only. Consumes **0% CPU and 0% RAM** while idle.

* **Event-Based GPU Clock Locking**

  * On battery: locks GPU clocks to **210–400 MHz** using `nvidia-smi -lgc`
  * On AC power: restores default behavior using `nvidia-smi -rgc`

* **Integrated System Power Profiles**
  Automatically switches CPU energy profiles via `power-profiles-daemon`.

* **Universal Distribution Support**
  Intelligent installer detects your base system:

  * Arch / Arch-based
  * Debian / Ubuntu
  * Fedora

* **Zero Configuration**
  Automatically detects your NVIDIA GPU **Bus ID** during installation.

---

## 🛠️ Requirements

* **GPU**
  NVIDIA RTX 20 / 30 / 40 series or GTX 16 series
  (Maxwell / Pascal *may* work, but `-lgc` support varies)

* **Drivers**
  Proprietary NVIDIA drivers (**nouveau is NOT supported**)

* **System**
  Any modern Linux distribution with:

  * `systemd`
  * `udev`

---

## 🚀 Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/ibodeth/nvidia-laptop-battery-optimizer.git
cd nvidia-laptop-battery-optimizer
chmod +x install.sh uninstall.sh
sudo ./install.sh
```

The installer will:

* Detect your distro
* Install required dependencies
* Detect your NVIDIA GPU Bus ID
* Register udev rules automatically

---

## 🗑️ Uninstallation

To completely remove the optimizer and reset your GPU clocks to factory defaults:

```bash
sudo ./uninstall.sh
```

---

## 🔍 How It Works

This project leverages the Linux kernel’s **udev subsystem** to react instantly to power state changes.

### 🔌 On Battery (Unplugged)

* `udev` detects AC removal
* GPU clocks are hardware-locked:

```bash
nvidia-smi -lgc 210,400
```

### ⚡ On AC Power (Plugged In)

* `udev` detects AC insertion
* GPU clock limits are removed:

```bash
nvidia-smi -rgc
```

This ensures **maximum battery efficiency on the go** and **full performance when plugged in**.

---

## 🤝 Contributing

Contributions are very welcome!

If you have:

* Fixes for specific laptop models
* Improvements for additional NVIDIA GPUs
* Extra power-saving ideas

Feel free to open an issue or submit a pull request.

---

## 👨‍💻 Author

**ibo**
AI Operations Student & Linux Enthusiast

---

⭐ If this project saved your battery (or your lap), consider starring the repo!
