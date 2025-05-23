#!/bin/bash

# Exit on error
set -e

TARGET_USER="cliff"
PASSWORD="intansagara"
USER_HOME="/home/$TARGET_USER"
BUILD_DIR="/tmp/suckless"
REPOS=("dwm" "dmenu" "st")
URL_BASE="https://git.suckless.org"

# Install git
pacman -S --noconfirm git

# Create user 'cliff'
useradd -m -G wheel -s /bin/bash "$TARGET_USER"
echo "$TARGET_USER:$PASSWORD" | chpasswd

# Install sudo
pacman -S --noconfirm sudo

# Allow wheel group to use sudo
sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers

# Install and enable UFW as user 'cliff'
sudo -u "$TARGET_USER" bash -c "
  sudo pacman -S --noconfirm ufw
  sudo ufw enable
  sudo systemctl enable --now ufw
"

# Install base-devel for make
pacman -S --noconfirm base-devel

# Prepare build directory
mkdir -p "$BUILD_DIR"
chown "$TARGET_USER:$TARGET_USER" "$BUILD_DIR"

# Clone, build, and clean up dwm, dmenu, st
for repo in "${REPOS[@]}"; do
  sudo -u "$TARGET_USER" bash -c "
    cd $BUILD_DIR
    git clone $URL_BASE/$repo
    cd $repo
    make clean install
  "
  rm -rf "$BUILD_DIR/$repo"
done

# Set up .xinitrc
echo "exec dwm" > "$USER_HOME/.xinitrc"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.xinitrc"

# Clean up
rmdir "$BUILD_DIR"

echo "Setup complete for user '$TARGET_USER'."
