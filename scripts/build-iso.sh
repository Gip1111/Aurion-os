#!/bin/bash
# AurionOS ISO Build Script (Cubic-based prototype)
#
# This script documents the steps performed inside a Cubic chroot
# to transform Ubuntu 24.04 LTS into an AurionOS prototype ISO.
#
# NOTE: This script is run INSIDE the Cubic chroot environment,
# not on the host system.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISTRO_DIR="${SCRIPT_DIR}/../distro"

echo "=== AurionOS ISO Build (Cubic Chroot) ==="

# --- Remove Ubuntu/GNOME packages ---
echo "[1/7] Removing Ubuntu branding and GNOME packages..."
while IFS= read -r pkg; do
    # Skip comments and empty lines
    [[ "$pkg" =~ ^#.*$ ]] && continue
    [[ -z "$pkg" ]] && continue
    apt remove -y "$pkg" 2>/dev/null || echo "  skip: $pkg (not installed)"
done < "${DISTRO_DIR}/remove-packages.list"

apt autoremove -y

# --- Install AurionOS packages ---
echo "[2/7] Installing AurionOS packages..."
while IFS= read -r pkg; do
    [[ "$pkg" =~ ^#.*$ ]] && continue
    [[ -z "$pkg" ]] && continue
    apt install -y "$pkg" 2>/dev/null || echo "  WARN: failed to install $pkg"
done < "${DISTRO_DIR}/packages.list"

# --- Install Plymouth theme ---
echo "[3/7] Installing Plymouth boot theme..."
mkdir -p /usr/share/plymouth/themes/aurion/
cp "${DISTRO_DIR}/plymouth-theme/aurion.plymouth" /usr/share/plymouth/themes/aurion/
cp "${DISTRO_DIR}/plymouth-theme/aurion.script" /usr/share/plymouth/themes/aurion/
# TODO: Copy aurion-logo.png to theme directory
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
    /usr/share/plymouth/themes/aurion/aurion.plymouth 200
update-alternatives --set default.plymouth /usr/share/plymouth/themes/aurion/aurion.plymouth

# --- Configure greetd ---
echo "[4/7] Configuring login manager..."
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml << 'EOF'
[terminal]
vt = 1

[default_session]
command = "labwc -s aurion-shell"
user = "greeter"
EOF

# Disable GDM, enable greetd
systemctl disable gdm3 2>/dev/null || true
systemctl enable greetd 2>/dev/null || true

# --- Install Wayland session ---
echo "[5/7] Installing AurionOS session..."
mkdir -p /usr/share/wayland-sessions
cat > /usr/share/wayland-sessions/aurion.desktop << 'EOF'
[Desktop Entry]
Name=AurionOS
Comment=AurionOS Desktop Session
Exec=aurion-session
Type=Application
DesktopNames=AurionOS
EOF

# --- Copy default user config ---
echo "[6/7] Setting up default user configuration..."
cp -r "${DISTRO_DIR}/skel/." /etc/skel/

# --- Setup Flatpak ---
echo "[7/7] Configuring Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

echo ""
echo "=== AurionOS ISO build steps complete ==="
echo "Exit the Cubic chroot and generate the ISO."
