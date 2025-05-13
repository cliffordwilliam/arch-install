# 🧪 Automated Arch Linux Installer

This repo contains a fully automated Arch Linux installation script with Hyprland, PipeWire, and UFW pre-configured.

## ⚠️ Warning

Change the default passwords in `preinstall.sh` before using this script!

---

## 🚀 How to Use

1. Boot from the official [Arch ISO](https://archlinux.org/download/).
2. Connect to the internet (Wi-Fi or Ethernet).
3. Run:

```bash
curl -LO https://raw.githubusercontent.com/YOUR_USERNAME/arch-install/main/preinstall.sh
curl -LO https://raw.githubusercontent.com/YOUR_USERNAME/arch-install/main/postinstall.sh
chmod +x preinstall.sh
./preinstall.sh

