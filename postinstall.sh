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
pacman -Syu --noconfirm git base-devel sudo xorg xorg-xinit libx11 libxft libxinerama filesystem

echo "=== Creating user '$TARGET_USER' ==="
useradd -m -G wheel -s /bin/bash "$TARGET_USER"
echo "$TARGET_USER:$PASSWORD" | chpasswd

echo "=== Enabling sudo for wheel group ==="
sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers

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

echo "=== Creating .xinitrc to launch dwm ==="
echo "exec dwm" > "$USER_HOME/.xinitrc"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.xinitrc"
chmod +x "$USER_HOME/.xinitrc"

echo "=== Cleaning up ==="
rmdir "$BUILD_DIR"

echo "✅ Setup complete."
