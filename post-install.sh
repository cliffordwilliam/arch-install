#!/bin/bash
set -euo pipefail

# Check internet first
if ! ping -c1 archlinux.org &>/dev/null; then
    echo "No internet connection!" >&2
    exit 1
fi

# Check: Must run as regular user
if [[ "$EUID" -eq 0 ]]; then
    echo "❌ Do NOT run this script as root. Please log in as your regular user." >&2
    exit 1
fi

# Check: Must have sudo privileges
if ! command -v sudo &>/dev/null; then
    echo "❌ sudo not found. Make sure your user has sudo privileges." >&2
    exit 1
fi

# --- System-Wide Setup (Requires sudo) ---
# Package Installation
echo "📦 Installing core packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm base-devel xorg xorg-xinit libx11 libxft libxinerama \
    alsa-utils firefox ufw git

# Audio Configuration
echo "🔊 Attempting to set Master volume..."
if amixer sset Master 50% unmute &>/dev/null; then
    echo "✓ Master audio channel set to 50%."
else
    echo "⚠️ Failed to set Master channel. Run 'alsamixer' manually to configure audio."
fi

# UFW Configuration
echo "🛡️ Configuring UFW firewall..."
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable

# --- User-Specific Setup (No sudo required) ---
# Ensure local bin directory exists and is in PATH
echo "⚙️ Setting up local bin directory..."
mkdir -p "$HOME/.local/bin"

if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "✓ Added ~/.local/bin to PATH"
fi

# Build suckless tools
echo "🛠️ Building suckless tools (dwm, st, dmenu)..."
BUILD_DIR="$HOME/suckless"
mkdir -p "$BUILD_DIR"

for repo in dwm st dmenu; do
    echo "-> Building $repo..."
    rm -rf "$BUILD_DIR/$repo"
    git clone --depth 1 "https://git.suckless.org/$repo" "$BUILD_DIR/$repo"
    pushd "$BUILD_DIR/$repo" >/dev/null
    make
    cp "$repo" "$HOME/.local/bin/"
    popd >/dev/null
done

echo "✓ Suckless tools installed to ~/.local/bin/"

# Configure xinitrc if needed
if [[ ! -f "$HOME/.xinitrc" ]]; then
    echo "⚙️ Creating .xinitrc..."
    cat > "$HOME/.xinitrc" <<'EOF'
exec dwm
EOF
    echo "✓ Created ~/.xinitrc"
fi

# Final instructions
echo ""
echo "═══════════════════════════════════════════════"
echo "✅ Post-installation complete!"
echo "═══════════════════════════════════════════════"
echo ""
echo "📝 Next steps:"
echo "  1. Log out and log back in (or run: source ~/.bashrc)"
echo "  2. Run 'startx' to start DWM"
echo "  3. Press Mod+Shift+Enter to open terminal (st)"
echo "  4. Press Mod+P to launch dmenu"
echo ""
echo "💡 Tips:"
echo "  - Default Mod key is Alt"
echo "  - Edit DWM: cd ~/suckless/dwm && make && cp dwm ~/.local/bin/"
echo "  - Configure audio: run 'alsamixer'"
echo ""
