#!/usr/bin/env bash
set -euo pipefail

echo "[+] Installing Hyprland and utilities..."
sudo pacman -S --noconfirm wayland xorg-xwayland hyprland waybar xdg-desktop-portal-hyprland kitty firefox

echo "[+] Installing PipeWire..."
sudo pacman -S --noconfirm pipewire wireplumber pipewire-audio pipewire-pulse
systemctl --user enable --now pipewire pipewire-pulse
loginctl enable-linger "$USER"

echo "[+] Installing UFW..."
sudo pacman -S --noconfirm ufw
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 8080
sudo ufw enable

echo "[+] Creating .bashrc..."
cat << 'EOF' > ~/.bashrc
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
EOF

echo "[+] Creating .bash_profile for Hyprland autostart..."
cat << 'EOF' > ~/.bash_profile
[[ -f ~/.bashrc ]] && . ~/.bashrc
if [[ -z \$DISPLAY && \$XDG_VTNR -eq 1 ]]; then
    exec dbus-run-session Hyprland
fi
EOF

echo "[+] Creating Hyprland config..."
mkdir -p ~/.config/hypr
echo "exec-once = waybar" > ~/.config/hypr/hyprland.conf

echo "[+] Creating Kitty config..."
mkdir -p ~/.config/kitty
touch ~/.config/kitty/kitty.conf

echo "[+] Fixing ownership..."
chown -R "$USER:$USER" ~

echo "[+] Removing self from .bash_profile to prevent re-running..."
sed -i '/postinstall.sh/d' ~/.bash_profile
rm ~/postinstall.sh

echo "[+] DONE! Reboot to enjoy Hyprland."
