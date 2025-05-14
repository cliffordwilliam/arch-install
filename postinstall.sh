#!/bin/bash
set -e

echo "==> Installing essential packages..."
sudo pacman -S --noconfirm \
  xorg-server xorg-xinit libxft libxinerama libx11 \
  git base-devel alsa-utils alsa-plugins networkmanager qutebrowser \
  xorg-xbacklight xorg-xrandr xorg-xsetroot xf86-input-libinput xf86-video-intel \
  ttf-dejavu

echo "==> Setting up locale..."
sudo sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sudo locale-gen
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf > /dev/null

echo "==> Enabling NetworkManager..."
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

echo "==> Creating qutebrowser wrapper script with software rendering fix..."
mkdir -p ~/.local/bin
cat > ~/.local/bin/qute <<EOF
#!/bin/bash
qutebrowser --temp-basedir -d -s qt.force_software_rendering qt-quick "\$@"
EOF
chmod +x ~/.local/bin/qute

if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

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

echo "==> Creating ~/.xinitrc with HDMI1 detection (clamshell mode)..."
cat > ~/.xinitrc <<EOF
# Monitor setup: Use HDMI1 if available, otherwise fallback to eDP1
if xrandr | grep -q "HDMI1 connected"; then
  xrandr --output HDMI1 --auto --primary --output eDP1 --off
else
  xrandr --output eDP1 --auto --primary --output HDMI1 --off
fi

slstatus &
exec dwm
EOF
chmod +x ~/.xinitrc

echo "==> Configuring auto-start of X on TTY1..."
BASH_PROFILE="$HOME/.bash_profile"
cp "$BASH_PROFILE" "$BASH_PROFILE.bak" 2>/dev/null || true

if ! grep -q "exec startx" "$BASH_PROFILE" 2>/dev/null; then
  echo '[[ -z \$DISPLAY && \$XDG_VTNR -eq 1 ]] && exec startx' >> "$BASH_PROFILE"
fi

# Fix ownership just in case script was run as root at any point
chown -R "$USER:$USER" ~/suckless

echo "==> Setup complete!"
echo ""
echo "👉 Run 'nmtui' to configure Wi-Fi."
echo "👉 Run 'alsamixer' to test sound."
echo "👉 Use 'qute' instead of 'qutebrowser' to launch with safe defaults."
echo "👉 Edit suckless configs in ~/suckless/ and run 'sudo make install' to apply changes."
echo ""
echo "🎧 To enable audio keybindings, add the following to dwm/config.h manually:"
cat <<EOC

// Audio keybindings (requires XF86 keys and alsa-utils)
{ 0, XF86XK_AudioLowerVolume, spawn, SHCMD("amixer sset Master 5%-") },
{ 0, XF86XK_AudioRaiseVolume, spawn, SHCMD("amixer sset Master 5%+") },
{ 0, XF86XK_AudioMute, spawn, SHCMD("amixer sset Master toggle") },
EOC
