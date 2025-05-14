#!/bin/bash
set -e

echo "==> Installing essential packages..."
sudo pacman -S --noconfirm xorg-server xorg-xinit libxft libxinerama libx11 \
  git base-devel alsa-utils networkmanager qutebrowser nmtui \
  xorg-xbacklight xorg-xrandr xorg-xsetroot xf86-input-libinput xf86-video-intel

echo "==> Enabling NetworkManager..."
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

echo "==> Cloning suckless repositories..."
mkdir -p ~/suckless
cd ~/suckless

for repo in dwm st dmenu slstatus; do
  if [ ! -d "$repo" ]; then
    git clone https://git.suckless.org/$repo
  fi
done

echo "==> Building and installing suckless software..."
for dir in dwm st dmenu slstatus; do
  cd ~/suckless/$dir
  make
  sudo make install
done

echo "==> Creating .xinitrc..."
cat > ~/.xinitrc <<EOF
slstatus &
exec dwm
EOF
chmod +x ~/.xinitrc

echo "==> Configuring auto-start of X on TTY1..."
if ! grep -q "exec startx" ~/.bash_profile 2>/dev/null; then
  echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> ~/.bash_profile
fi

echo "==> Setup complete!"
echo ""
echo "👉 Run 'nmtui' to configure Wi-Fi."
echo "👉 Run 'alsamixer' to test sound."
echo "👉 Edit suckless configs in ~/suckless/ and run 'sudo make install' to apply changes."
echo ""
echo "🎧 To enable audio keybindings, add the following to dwm/config.h manually:"
cat <<EOC

// Audio keybindings (requires XF86 keys and alsa-utils)
{ 0, XF86XK_AudioLowerVolume, spawn, SHCMD("amixer sset Master 5%-") },
{ 0, XF86XK_AudioRaiseVolume, spawn, SHCMD("amixer sset Master 5%+") },
{ 0, XF86XK_AudioMute, spawn, SHCMD("amixer sset Master toggle") },
EOC
