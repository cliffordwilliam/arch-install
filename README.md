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
curl -O https://raw.githubusercontent.com/cliffordwilliam/arch-install/main/pre-install.sh
curl -O https://raw.githubusercontent.com/cliffordwilliam/arch-install/main/post-install.sh
bash pre-install.sh
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
startx to start ui
```

## Different machine different battery reference, this is how you check for Linux

```bash
for b in /sys/class/power_supply/*; do     if grep -q "Battery" "$b/type" 2>/dev/null; then         basename "$b";     fi; done
```

Given that battery is BAT0.

Make sure you first exit dwm, since we cannot cp to build of the slstatus if its running.

```bash
alt + shift + Q
```

Enter the repo we cloned from post install.

```bash
cd ~/suckless/slstatus
```

Then edit the `config.h`, add new `battery_perc`.

```config.h
static const struct arg args[] = {
        /* function format          argument */
        { datetime, "%s",           "%F %T" },
        { battery_state, " %s", "BAT0" },
        { battery_perc, " %s%%", "BAT0" },
};
```

Save the file and rebuild and copy build to `~/.local/bin/`.

```bash
make clean
make
cp slstatus ~/.local/bin/
```

Now `startx` again to start dwm again.

You should see the battery percentage now.
