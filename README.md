# 🧪 Automated Arch Linux Installer

Just run the `install.sh` script and it does everything for you.

---

## 🚀 How to Use

1. Get and boot from the official [Arch ISO](https://archlinux.org/download/).
2. Connect to the internet.

```bash
bash <(curl -s https://raw.githubusercontent.com/cliffordwilliam/arch-install/main/install.sh)
```

3. Reboot.
4. Login.
5. `startx`

## Connect to internet in live env

run

```bash
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "WIFI NAME"
exit
```

## Connect to internet in after logging in

run

```bash
nmtui
```

1. pick "Activate a connection"
2. pick "Quit"
