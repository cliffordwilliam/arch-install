#!/bin/bash

# Exit on error
set -e

read -p "Enter name for user: " TARGET_USER
read -s -p "Enter password for user $TARGET_USER: " PASSWORD
echo
USER_HOME="/home/$TARGET_USER"
BUILD_DIR="/tmp/suckless"
REPOS=("dwm" "st")
URL_BASE="https://git.suckless.org"

echo "=== Installing dependencies for suckless ==="
pacman -Syu --noconfirm git base-devel sudo xorg xorg-xinit libx11 libxft libxinerama

echo "=== Installing audio and browser packages ==="
pacman -S --noconfirm alsa-utils firefox

echo "=== Installing picom compositor ==="
pacman -S --noconfirm picom

echo "=== Creating user '$TARGET_USER' if we have not made user yet ==="
if id "$TARGET_USER" &>/dev/null; then
  echo "User $TARGET_USER already exists. Skipping user creation and sudo setup."
  SKIP_USER_SETUP=true
else
  SKIP_USER_SETUP=false
fi
if [ "$SKIP_USER_SETUP" = false ]; then
  echo "=== Creating user '$TARGET_USER' ==="
  useradd -m -G wheel -s /bin/bash "$TARGET_USER"
  echo "$TARGET_USER:$PASSWORD" | chpasswd

  echo "=== Enabling sudo for wheel group ==="
  sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
fi

echo "=== Setting up firewall ==="
pacman -S --noconfirm ufw
systemctl enable --now ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable

echo "=== Setting up build directory ==="
rm -rf "$BUILD_DIR"
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
  TIME=$(date '+%a %b %d %Y %H:%M')

  xsetroot -name "BAT: $BAT% ($STATUS) | $TIME"
  sleep 60
done
EOF

chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.custom-dwm-status.sh"
chmod +x "$USER_HOME/.custom-dwm-status.sh"

echo "=== Installing feh for wallpaper ==="
pacman -S --noconfirm feh
WALLPAPER_URL="https://raw.githubusercontent.com/cliffordwilliam/arch-install/main/wallpaper.jpg"
WALLPAPER_PATH="$USER_HOME/wallpaper.jpg"
echo "Downloading wallpaper..."
curl -L "$WALLPAPER_URL" -o "$WALLPAPER_PATH"
chown "$TARGET_USER:$TARGET_USER" "$WALLPAPER_PATH"

echo "=== Creating picom config ==="
mkdir -p "$USER_HOME/.config/picom"
cat << 'EOF' > "$USER_HOME/.config/picom/picom.conf"
backend = "glx";
vsync = true;

opacity-rule = [
  "80:class_g = 'st-256color'",
];
EOF
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.config/picom"

echo "=== Creating .xinitrc to launch dwm ==="
# Ensure home directory exists
mkdir -p "$USER_HOME"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME"
# Create .xinitrc
printf "%s\n" \
  "feh --bg-scale \"$WALLPAPER_PATH\" &" \
  "picom &" \
  "~/.custom-dwm-status.sh &" \
  "exec dwm" > "$USER_HOME/.xinitrc"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.xinitrc"
chmod +x "$USER_HOME/.xinitrc"

echo "=== Setting volume to 50% and unmuting ==="
amixer sset Master 50%
amixer sset Master unmute

echo "=== Cleaning up ==="
rm -rf "$BUILD_DIR"

echo "✅ Setup complete. Reboot and login as $TARGET_USER"
