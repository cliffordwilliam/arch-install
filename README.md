# 🧪 Automated Arch Linux Installer

Just run the script and it does everything for you.

## ⚠️ Warning

Check the script and edit the content before running it as needed.

---

## 🚀 How to Use

1. Boot from the official [Arch ISO](https://archlinux.org/download/).
2. Connect to the internet.
3. Run preinstall in live env, run postinstall after logging in:

```bash
curl -LO https://raw.githubusercontent.com/cliffordwilliam/arch-install/main/preinstall.sh
curl -LO https://raw.githubusercontent.com/cliffordwilliam/arch-install/main/postinstall.sh
chmod +x preinstall.sh
bash -x preinstall.sh
```

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

## After postinstall

```bash
login as user
startx to start ui
```

