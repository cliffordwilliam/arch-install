#!/bin/bash

set -euo pipefail

read -rp "Enter name for user: " TARGET_USER
read -srp "Enter password for user $TARGET_USER: " PASSWORD
echo

USER_HOME="/home/$TARGET_USER"
BUILD_DIR="/tmp/suckless"
REPOS=("dwm" "st")
URL_BASE="https://git.suckless.org"
WALLPAPER_URL="https://raw.githubusercontent.com/cliffordwilliam/arch-install/main/wallpaper.jpg"
WALLPAPER_PATH="$USER_HOME/wallpaper.jpg"

echo "=== Installing general packages ==="
pacman -Syu --noconfirm
# git, sudo, dwm deps
# audio util, browser, curl
# nvim
# firewall
# wallpaper and transparent terminal
pacman -S --noconfirm git github-cli openssh sudo base-devel xorg xorg-xinit libx11 libxft libxinerama \
  alsa-utils firefox curl \
  neovim xclip gcc make unzip zip ripgrep fd tmux \
  ufw \
  feh picom

echo "=== Checking if user '$TARGET_USER' already exists ==="
if id "$TARGET_USER" &>/dev/null; then
  echo "User $TARGET_USER already exists. Skipping user creation."
else
  echo "=== Creating user '$TARGET_USER' ==="
  useradd -m -G wheel -s /bin/bash "$TARGET_USER"
  echo "$TARGET_USER:$PASSWORD" | chpasswd

  echo "=== Enabling sudo for wheel group ==="
  sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
fi

echo "=== Installing Node Version Manager (nvm) and Node.js LTS for $TARGET_USER ==="
sudo -u "$TARGET_USER" HOME="$USER_HOME" bash -c "
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

  # Add nvm env vars to .bashrc
  cat <<'EOF' >> \"$HOME/.bashrc\"

export NVM_DIR=\"\$([ -z \"\${XDG_CONFIG_HOME-}\" ] && printf %s \"\$HOME/.nvm\" || printf %s \"\$XDG_CONFIG_HOME/nvm\")\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\" # This loads nvm
EOF

  # Source nvm and install latest LTS node version
  export NVM_DIR=\"$HOME/.nvm\"
  [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"

  nvm install --lts
  nvm alias default lts/*
  nvm use --lts
"

echo "=== Configuring global Git user name and email for $TARGET_USER ==="
read -rp "Enter Git user name: " GIT_NAME
read -rp "Enter Git email: " GIT_EMAIL

sudo -u "$TARGET_USER" git config --global user.name "$GIT_NAME"
sudo -u "$TARGET_USER" git config --global user.email "$GIT_EMAIL"
sudo -u "$TARGET_USER" git config --global init.defaultBranch main
sudo -u "$TARGET_USER" git config --global pull.rebase false

echo "=== Preparing user home and config directories ==="
install -d -o "$TARGET_USER" -g "$TARGET_USER" "$USER_HOME/.config"

echo "=== Cloning kickstart.nvim config for user $TARGET_USER ==="
rm -rf "$USER_HOME/.config/nvim"
sudo -u "$TARGET_USER" git clone --depth 1 https://github.com/nvim-lua/kickstart.nvim.git "$USER_HOME/.config/nvim"

echo "=== Generating SSH key for GitHub ==="
install -d -o "$TARGET_USER" -g "$TARGET_USER" "$USER_HOME/.ssh"
rm -rf "$USER_HOME/.ssh/id_ed25519"
sudo -u "$TARGET_USER" ssh-keygen -t ed25519 -C "$TARGET_USER@$(hostname)" -f "$USER_HOME/.ssh/id_ed25519" -N ""

echo "=== Setting up ufw firewall ==="
systemctl enable --now ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable

echo "=== Creating build directory and cloning suckless repos ==="
rm -rf "$BUILD_DIR"
install -d -o "$TARGET_USER" -g "$TARGET_USER" "$BUILD_DIR"

for repo in "${REPOS[@]}"; do
  sudo -u "$TARGET_USER" git clone "$URL_BASE/$repo" "$BUILD_DIR/$repo"
  pushd "$BUILD_DIR/$repo" >/dev/null
  sudo -u "$TARGET_USER" make clean
  make install
  popd >/dev/null
  rm -rf "$BUILD_DIR/$repo"
done

echo "=== Creating custom DWM status script ==="
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
chmod +x "$USER_HOME/.custom-dwm-status.sh"

echo "=== Installing feh for wallpaper ==="
echo "Downloading wallpaper..."
curl -L "$WALLPAPER_URL" -o "$WALLPAPER_PATH"

echo "=== Creating picom configuration ==="
install -d -o "$TARGET_USER" -g "$TARGET_USER" "$USER_HOME/.config/picom"
cat <<'EOF' > "$USER_HOME/.config/picom/picom.conf"
backend = "glx";
vsync = true;

opacity-rule = [
  "80:class_g = 'st-256color'",
];
EOF

echo "=== Creating .xinitrc to launch dwm ==="
printf "%s\n" \
  "feh --bg-scale \"$WALLPAPER_PATH\" &" \
  "picom &" \
  "~/.custom-dwm-status.sh &" \
  "exec dwm" > "$USER_HOME/.xinitrc"
chmod +x "$USER_HOME/.xinitrc"

echo "=== Creating .bash_profile to launch startx on login ==="
cat <<'EOF' > "$USER_HOME/.bash_profile"
if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
  exec startx
fi
EOF
chmod +x "$USER_HOME/.bash_profile"

echo "=== Setting volume to 50% and unmuting ==="
amixer sset Master 50% unmute

echo "=== Fixing ownership of user files ==="
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME"

echo "=== Cleaning up ==="
rm -rf "$BUILD_DIR"

echo "✅ Setup complete. Reboot and login as $TARGET_USER. Do not forget to use github cli to push ssh key to remote, see readme if you forget"
