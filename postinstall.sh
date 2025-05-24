#!/bin/bash

# Exit on error
set -e

TARGET_USER="cliff"
PASSWORD="Intansagara"
USER_HOME="/home/$TARGET_USER"
BUILD_DIR="/tmp/suckless"
REPOS=("dwm" "dmenu" "st")
URL_BASE="https://git.suckless.org"

echo "=== Installing dependencies ==="
pacman -Syu --noconfirm git base-devel sudo xorg xorg-xinit libx11 libxft libxinerama

echo "=== Installing audio and browser packages ==="
pacman -S --noconfirm alsa-utils pipewire-pulse wireplumber firefox

echo "=== Enabling audio services ==="
systemctl enable --now pipewire pipewire-pulse wireplumber

echo "=== Creating user '$TARGET_USER' ==="
useradd -m -G wheel -s /bin/bash "$TARGET_USER"
echo "$TARGET_USER:$PASSWORD" | chpasswd

echo "=== Enabling sudo for wheel group ==="
sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers

echo "=== Setting up firewall ==="
pacman -S --noconfirm ufw
systemctl enable --now ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable

echo "=== Setting up build directory ==="
mkdir -p "$BUILD_DIR"
chown "$TARGET_USER:$TARGET_USER" "$BUILD_DIR"

echo "=== Cloning and building suckless tools ==="
for repo in "${REPOS[@]}"; do
  sudo -u "$TARGET_USER" bash -c "
    cd $BUILD_DIR
    git clone $URL_BASE/$repo
  "
  cd "$BUILD_DIR/$repo"
  sudo -u "$TARGET_USER" make clean
  make install
  rm -rf "$BUILD_DIR/$repo"
done

echo "=== Creating custom battery/time status script ==="
cat <<'EOF' > "$USER_HOME/.custom-dwm-status.sh"
#!/bin/bash

while true; do
  BAT=$(cat /sys/class/power_supply/BAT0/capacity)
  STATUS=$(cat /sys/class/power_supply/BAT0/status)
  TIME=$(date '+%a %H:%M')

  xsetroot -name "BAT: $BAT% ($STATUS) | $TIME"
  sleep 60
done
EOF

chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.custom-dwm-status.sh"
chmod +x "$USER_HOME/.custom-dwm-status.sh"

echo "=== Creating .xinitrc to launch dwm ==="
# Ensure home directory exists
mkdir -p "$USER_HOME"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME"
# Create .xinitrc
printf "%s\n" "~/.custom-dwm-status.sh &" "exec dwm" > "$USER_HOME/.xinitrc"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.xinitrc"
chmod +x "$USER_HOME/.xinitrc"

echo "=== Setting volume to 50% and unmuting ==="
sudo -u "$TARGET_USER" amixer sset Master 50%
sudo -u "$TARGET_USER" amixer sset Master unmute

echo "=== Cleaning up ==="
rmdir "$BUILD_DIR"

echo "✅ Setup complete."
