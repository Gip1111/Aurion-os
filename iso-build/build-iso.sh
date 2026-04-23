#!/bin/bash
# ============================================================
# AurionOS ISO Builder — Master Script
# ============================================================
# Produces: aurion-os-0.1-alpha-amd64.iso
#
# Requirements:
#   - Ubuntu 24.04 build machine (VM, VPS, or CI)
#   - ~10 GB free disk space
#   - Internet connection (to download packages)
#   - Root access (sudo)
#
# Usage:
#   sudo ./iso-build/build-iso.sh
#
# Output:
#   ./iso-build/output/aurion-os-0.1-alpha-amd64.iso
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ISO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# --- Sanity checks ---
[ "$(id -u)" -eq 0 ] || fail "Must run as root: sudo ./iso-build/build-iso.sh"
command -v lb &>/dev/null || {
    log "Installing live-build..."
    apt update -qq && apt install -y -qq live-build
}
command -v debootstrap &>/dev/null || apt install -y -qq debootstrap

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$REPO_DIR/iso-build/work"
OUTPUT_DIR="$REPO_DIR/iso-build/output"
ISO_NAME="aurion-os-0.1-alpha-amd64"

log "╔══════════════════════════════════════════════╗"
log "║     AurionOS ISO Builder — Alpha v0.1        ║"
log "╚══════════════════════════════════════════════╝"
log "Repo: $REPO_DIR"
log "Build dir: $BUILD_DIR"
echo ""

# --- Step 0: Build AurionOS components (non-fatal) ---
step "[0/6] Building AurionOS components..."

# Build shell (non-fatal — ISO works without it)
if [ ! -f "$REPO_DIR/shell/build/aurion-shell" ]; then
    log "Building Aurion Shell..."
    (
        cd "$REPO_DIR/shell"
        mkdir -p build && cd build
        cmake .. -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -20
        make -j"$(nproc)" 2>&1 | tail -20
    ) || warn "Shell build failed — continuing without it"
fi

# Build hardware scanner (non-fatal)
if [ ! -f "$REPO_DIR/hardware-compat/target/release/aurion-hwcompat" ]; then
    log "Building Hardware Scanner..."
    (
        cd "$REPO_DIR/hardware-compat"
        if command -v cargo &>/dev/null; then
            cargo build --release 2>&1 | tail -20
        elif [ -n "${SUDO_USER:-}" ] && [ -f "/home/$SUDO_USER/.cargo/bin/cargo" ]; then
            sudo -u "$SUDO_USER" /home/$SUDO_USER/.cargo/bin/cargo build --release 2>&1 | tail -20
        else
            echo "Rust not found — skipping hardware scanner"
        fi
    ) || warn "Hardware scanner build failed — continuing without it"
fi

# Build diagnostics (non-fatal)
if [ ! -f "$REPO_DIR/diagnostics/target/release/aurion-diag" ]; then
    log "Building Diagnostics..."
    (
        cd "$REPO_DIR/diagnostics"
        if command -v cargo &>/dev/null; then
            cargo build --release 2>&1 | tail -20
        elif [ -n "${SUDO_USER:-}" ] && [ -f "/home/$SUDO_USER/.cargo/bin/cargo" ]; then
            sudo -u "$SUDO_USER" /home/$SUDO_USER/.cargo/bin/cargo build --release 2>&1 | tail -20
        else
            echo "Rust not found — skipping diagnostics"
        fi
    ) || warn "Diagnostics build failed — continuing without it"
fi

# --- Step 1: Clean previous build ---
step "[1/6] Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
cd "$BUILD_DIR"

# --- Step 2: Configure live-build ---
step "[2/6] Configuring live-build..."

lb config \
    --distribution noble \
    --parent-distribution noble \
    --parent-archive-areas "main restricted universe multiverse" \
    --archive-areas "main restricted universe multiverse" \
    --architectures amd64 \
    --binary-images iso-hybrid \
    --iso-application "AurionOS" \
    --iso-publisher "AurionOS Project" \
    --iso-volume "AurionOS Alpha 0.1" \
    --linux-flavours generic \
    --linux-packages "linux-image" \
    --mode ubuntu \
    --system live \
    --apt-recommends false \
    --memtest none

# --- Step 3: Package lists ---
step "[3/6] Configuring packages..."

# Packages to install
cat > config/package-lists/aurion.list.chroot << 'PACKAGES'
# === Core system ===
systemd
dbus
network-manager
wpasupplicant
casper
isolinux
syslinux-utils

# === Compositor & display ===
labwc
swaybg
xwayland
greetd

# === Audio ===
pipewire
pipewire-pulse
wireplumber

# === Qt6 runtime (for shell) ===
libqt6core6t64
libqt6gui6t64
libqt6quick6
libqt6qml6
libqt6dbus6t64
libqt6waylandclient6
qml6-module-qtquick
qml6-module-qtquick-layouts
qml6-module-qtquick-window

# === Terminal & basic apps ===
foot
thunar
mousepad
firefox

# === Firmware & hardware ===
linux-firmware
fwupd

# === Flatpak ===
flatpak

# === Fonts ===
fonts-inter
fonts-jetbrains-mono

# === Python (AI service) ===
python3
python3-pip
python3-venv
python3-httpx

# === System tools ===
btrfs-progs
htop
curl
wget
git

# === Installer ===
calamares

# === Plymouth ===
plymouth
plymouth-themes
PACKAGES

# Packages to remove (Ubuntu/GNOME branding)
cat > config/package-lists/remove.list.chroot << 'REMOVELIST'
# These are listed but live-build handles removal differently
# See hooks for actual removal
REMOVELIST

# --- Step 4: Copy AurionOS files into the ISO filesystem ---
step "[4/6] Copying AurionOS files into ISO..."

CHROOT="config/includes.chroot"
mkdir -p "$CHROOT"

# --- Binaries ---
mkdir -p "$CHROOT/usr/local/bin"

# Shell binary
if [ -f "$REPO_DIR/shell/build/aurion-shell" ]; then
    cp "$REPO_DIR/shell/build/aurion-shell" "$CHROOT/usr/local/bin/"
    log "  Shell binary copied"
fi

# Hardware scanner
if [ -f "$REPO_DIR/hardware-compat/target/release/aurion-hwcompat" ]; then
    cp "$REPO_DIR/hardware-compat/target/release/aurion-hwcompat" "$CHROOT/usr/local/bin/"
    log "  Hardware scanner copied"
fi

# Diagnostics
if [ -f "$REPO_DIR/diagnostics/target/release/aurion-diag" ]; then
    cp "$REPO_DIR/diagnostics/target/release/aurion-diag" "$CHROOT/usr/local/bin/"
    log "  Diagnostics copied"
fi

# Session script
cp "$REPO_DIR/distro/bin/aurion-session" "$CHROOT/usr/local/bin/"
chmod +x "$CHROOT/usr/local/bin/aurion-session"

# --- Session registration ---
mkdir -p "$CHROOT/usr/share/wayland-sessions"
cp "$REPO_DIR/distro/wayland-sessions/aurion.desktop" "$CHROOT/usr/share/wayland-sessions/"

# --- Default user config (skel) ---
mkdir -p "$CHROOT/etc/skel/.config/labwc"
cp "$REPO_DIR/distro/skel/.config/labwc/rc.xml" "$CHROOT/etc/skel/.config/labwc/"
cp "$REPO_DIR/distro/skel/.config/labwc/environment" "$CHROOT/etc/skel/.config/labwc/"

# Autostart for live session (uses full paths)
cat > "$CHROOT/etc/skel/.config/labwc/autostart" << 'AUTOSTART'
swaybg -c '#0A0E1A' &
/usr/local/bin/aurion-shell &
/usr/local/bin/aurion-hwcompat --scan --json > /tmp/aurion-hw-report.json 2>/dev/null &
AUTOSTART

# --- AI service ---
mkdir -p "$CHROOT/opt/aurion-ai"
cp -r "$REPO_DIR/ai-services/aurion_ai" "$CHROOT/opt/aurion-ai/"
cp "$REPO_DIR/ai-services/pyproject.toml" "$CHROOT/opt/aurion-ai/"
mkdir -p "$CHROOT/etc/aurion"
cp "$REPO_DIR/ai-services/config/ai.toml" "$CHROOT/etc/aurion/"
mkdir -p "$CHROOT/etc/skel/.config/aurion"
cp "$REPO_DIR/ai-services/config/ai.toml" "$CHROOT/etc/skel/.config/aurion/"

# --- Calamares installer ---
mkdir -p "$CHROOT/opt/aurion-calamares/branding/aurion"
mkdir -p "$CHROOT/opt/aurion-calamares/modules"
cp "$REPO_DIR/iso-build/calamares/settings.conf" "$CHROOT/opt/aurion-calamares/"
cp "$REPO_DIR/iso-build/calamares/branding/aurion/branding.desc" "$CHROOT/opt/aurion-calamares/branding/aurion/"
cp "$REPO_DIR/iso-build/calamares/branding/aurion/show.qml" "$CHROOT/opt/aurion-calamares/branding/aurion/"
cp "$REPO_DIR/iso-build/calamares/modules/"*.conf "$CHROOT/opt/aurion-calamares/modules/"
log "  Calamares config copied"

# Copy installer hook
cp "$REPO_DIR/iso-build/hooks/0200-calamares-setup.hook.chroot" "config/hooks/live/" 2>/dev/null || true
cp "$REPO_DIR/iso-build/hooks/0200-calamares-setup.hook.chroot" "config/hooks/normal/" 2>/dev/null || true
cp "$REPO_DIR/iso-build/hooks/0200-calamares-setup.hook.chroot" "config/hooks/" 2>/dev/null || true
chmod +x config/hooks/live/*.chroot config/hooks/normal/*.chroot config/hooks/*.chroot 2>/dev/null || true

# --- Plymouth theme ---
mkdir -p "$CHROOT/usr/share/plymouth/themes/aurion"
cp "$REPO_DIR/distro/plymouth-theme/aurion.plymouth" "$CHROOT/usr/share/plymouth/themes/aurion/"
cp "$REPO_DIR/distro/plymouth-theme/aurion.script" "$CHROOT/usr/share/plymouth/themes/aurion/"

# --- greetd config (auto-login for live, password for installed) ---
mkdir -p "$CHROOT/etc/greetd"
cat > "$CHROOT/etc/greetd/config.toml" << 'GREETD'
[terminal]
vt = 1

[default_session]
command = "/usr/local/bin/aurion-session"
user = "aurion"
GREETD

# --- Step 5: Chroot hooks (run during build inside the ISO filesystem) ---
step "[5/6] Creating build hooks..."

mkdir -p config/hooks/live config/hooks/normal

cat > config/hooks/live/0100-aurion-setup.hook.chroot << 'HOOK'
#!/bin/bash
# AurionOS chroot hook — runs during ISO build inside the target filesystem
set -e

echo "[AurionOS] Configuring system..."

# --- Remove Ubuntu/GNOME branding ---
apt-get remove -y --purge \
    ubuntu-wallpapers ubuntu-wallpapers-noble \
    yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon yaru-theme-sound \
    gdm3 gnome-shell gnome-session ubuntu-session \
    gnome-terminal gnome-text-editor gnome-calculator snap-store \
    2>/dev/null || true

apt-get autoremove -y 2>/dev/null || true

# --- Set Plymouth theme ---
if [ -f /usr/share/plymouth/themes/aurion/aurion.plymouth ]; then
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
        default.plymouth /usr/share/plymouth/themes/aurion/aurion.plymouth 200 || true
    update-alternatives --set default.plymouth \
        /usr/share/plymouth/themes/aurion/aurion.plymouth || true
fi

# --- Enable greetd, disable GDM ---
systemctl disable gdm3 2>/dev/null || true
systemctl enable greetd 2>/dev/null || true

# --- Create live user ---
if ! id aurion &>/dev/null; then
    useradd -m -s /bin/bash -G sudo,video,audio,input aurion
    echo "aurion:aurion" | chpasswd
    echo "aurion ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/aurion
fi

# --- Install AI service ---
cd /opt/aurion-ai
python3 -m pip install --break-system-packages -e . 2>/dev/null || true

# --- Flatpak setup ---
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# --- OS identification ---
cat > /etc/os-release << 'OSREL'
PRETTY_NAME="AurionOS Alpha 0.1"
NAME="AurionOS"
VERSION_ID="0.1"
VERSION="0.1 (Alpha)"
ID=aurion
ID_LIKE=ubuntu
HOME_URL="https://aurion-os.dev"
BUG_REPORT_URL="https://github.com/aurion-os/aurion-os/issues"
UBUNTU_CODENAME=noble
OSREL

echo "AurionOS Alpha 0.1" > /etc/aurion-release

# --- Install dummy packages to bypass live-build bug ---
if ls /opt/dummy-pkgs/*.deb 1> /dev/null 2>&1; then
    dpkg -i /opt/dummy-pkgs/*.deb || true
    rm -rf /opt/dummy-pkgs
fi

# Create the missing theme directory inside the chroot to prevent 'cp' from crashing
mkdir -p /usr/share/syslinux/themes/ubuntu-oneiric/isolinux-live
touch /usr/share/syslinux/themes/ubuntu-oneiric/isolinux-live/dummy-theme-file.txt

# Create missing bootlogo.tar.gz inside the chroot to prevent 'tar' from crashing
mkdir -p /usr/share/gfxboot-theme-ubuntu
mkdir -p /tmp/gfxboot-dummy
echo "dummy" > /tmp/gfxboot-dummy/dummy.txt
# Create a valid cpio archive for bootlogo
(cd /tmp/gfxboot-dummy && echo "dummy.txt" | cpio -o -H newc > bootlogo)
touch /tmp/gfxboot-dummy/message
touch /tmp/gfxboot-dummy/syslinux.cfg
touch /tmp/gfxboot-dummy/isolinux.cfg
tar -czf /usr/share/gfxboot-theme-ubuntu/bootlogo.tar.gz -C /tmp/gfxboot-dummy .

# Fix for outdated live-build syslinux paths: copy files to legacy locations
echo "Copying isolinux files to legacy paths for live-build..."
mkdir -p /usr/lib/syslinux
if [ -f /usr/lib/ISOLINUX/isolinux.bin ]; then
    cp /usr/lib/ISOLINUX/isolinux.bin /usr/lib/syslinux/isolinux.bin
fi
if [ -d /usr/lib/syslinux/modules/bios ]; then
    cp -r /usr/lib/syslinux/modules/bios/* /usr/lib/syslinux/ 2>/dev/null || true
fi

echo "[AurionOS] Configuration complete."
HOOK
chmod +x config/hooks/live/0100-aurion-setup.hook.chroot

# Hook to fix dangling initrd symlinks (runs inside chroot, before lb_chroot_hacks)
cat > config/hooks/live/9999-fix-symlinks.hook.chroot << 'SYMLINKFIX'
#!/bin/bash
# Fix dangling boot symlinks (known live-build issue on Ubuntu 24.04)
# lb_chroot_hacks runs "chmod 0644 chroot/boot/*" which fails on dangling symlinks
echo "[AurionOS] Fixing dangling boot symlinks..."
for f in /boot/initrd.img /boot/initrd.img.old /boot/vmlinuz.old; do
    if [ -L "$f" ] && [ ! -e "$f" ]; then
        rm -f "$f"
        echo "  Removed dangling symlink: $f"
    fi
done
echo "[AurionOS] Boot symlinks fixed."
SYMLINKFIX
chmod +x config/hooks/live/9999-fix-symlinks.hook.chroot

# Hook to force initramfs generation (in case it was deferred/skipped)
cat > config/hooks/live/9998-force-initramfs.hook.chroot << 'INITRAMFS'
#!/bin/bash
echo "[AurionOS] Forcing initramfs generation..."
update-initramfs -c -k all || true
INITRAMFS
chmod +x config/hooks/live/9998-force-initramfs.hook.chroot

# Duplicate hooks to ensure they run on any version of live-build
cp config/hooks/live/*.chroot config/hooks/normal/ 2>/dev/null || true
cp config/hooks/live/*.chroot config/hooks/ 2>/dev/null || true
chmod +x config/hooks/normal/*.chroot config/hooks/*.chroot 2>/dev/null || true

# --- Step 6: Build the ISO ---
step "[6/6] Building ISO... (this takes 10-20 minutes)"
echo ""

# --- Workaround for live-build ubuntu mode syslinux theme bug ---
step "[5.5/6] Creating dummy packages for obsolete syslinux themes..."
apt-get install -y -qq equivs
mkdir -p config/includes.chroot/opt/dummy-pkgs

# Create dummy package for syslinux-themes-ubuntu-oneiric
cat > /tmp/dummy-syslinux.control <<EOF
Section: misc
Priority: optional
Standards-Version: 3.9.2
Package: syslinux-themes-ubuntu-oneiric
Version: 99.0
Description: Dummy package to bypass live-build bug
EOF
(cd /tmp && equivs-build dummy-syslinux.control >/dev/null)
mv /tmp/syslinux-themes-ubuntu-oneiric_*.deb config/includes.chroot/opt/dummy-pkgs/

# Create dummy package for gfxboot-theme-ubuntu
cat > /tmp/dummy-gfxboot.control <<EOF
Section: misc
Priority: optional
Standards-Version: 3.9.2
Package: gfxboot-theme-ubuntu
Version: 99.0
Description: Dummy package to bypass live-build bug
EOF
(cd /tmp && equivs-build dummy-gfxboot.control >/dev/null)
mv /tmp/gfxboot-theme-ubuntu_*.deb config/includes.chroot/opt/dummy-pkgs/

# Create the missing theme directory on the host to prevent 'cp' from crashing in binary_syslinux
mkdir -p /usr/share/syslinux/themes/ubuntu-oneiric/isolinux-live
touch /usr/share/syslinux/themes/ubuntu-oneiric/isolinux-live/dummy-theme-file.txt

# --- Fix live-build syslinux script on the host ---
step "[5.8/6] Patching live-build syslinux script for robust ISO generation..."
if [ -f /usr/lib/live/build/lb_binary_syslinux ]; then
    # Suppress cp errors for empty wildcards
    sed -i 's@cp binary/isolinux/\*.fnt@cp binary/isolinux/*.fnt 2>/dev/null || true@g' /usr/lib/live/build/lb_binary_syslinux
    sed -i 's@cp binary/isolinux/\*.hlp@cp binary/isolinux/*.hlp 2>/dev/null || true@g' /usr/lib/live/build/lb_binary_syslinux
    sed -i 's@cp binary/isolinux/\*.jpg@cp binary/isolinux/*.jpg 2>/dev/null || true@g' /usr/lib/live/build/lb_binary_syslinux
    sed -i 's@cp binary/isolinux/langlist@cp binary/isolinux/langlist 2>/dev/null || true@g' /usr/lib/live/build/lb_binary_syslinux

    # Append robust isolinux.bin generation logic
    cat >> /usr/lib/live/build/lb_binary_syslinux << 'EOF'

# --- AURION ROBUST ISOLINUX FIX ---
echo "[AurionOS] Ensuring isolinux.bin exists in binary/isolinux..."
mkdir -p binary/isolinux

# Search for isolinux.bin in all likely places and copy it
if [ -f chroot/usr/lib/ISOLINUX/isolinux.bin ]; then
    cp chroot/usr/lib/ISOLINUX/isolinux.bin binary/isolinux/isolinux.bin
elif [ -f chroot/usr/lib/syslinux/isolinux.bin ]; then
    cp chroot/usr/lib/syslinux/isolinux.bin binary/isolinux/isolinux.bin
elif [ -f /usr/lib/ISOLINUX/isolinux.bin ]; then
    cp /usr/lib/ISOLINUX/isolinux.bin binary/isolinux/isolinux.bin
fi

# Same for c32 modules
if [ -d chroot/usr/lib/syslinux/modules/bios ]; then
    cp chroot/usr/lib/syslinux/modules/bios/* binary/isolinux/ 2>/dev/null || true
elif [ -d chroot/usr/lib/syslinux ]; then
    cp chroot/usr/lib/syslinux/*.c32 binary/isolinux/ 2>/dev/null || true
fi

echo "[AurionOS] Debug: binary/isolinux contents before genisoimage:"
ls -lah binary/isolinux/ || true

# Explicit check
if [ ! -f binary/isolinux/isolinux.bin ]; then
    echo "ERROR: isolinux.bin is missing from binary/isolinux!"
    echo "This will cause genisoimage to fail. Aborting."
    exit 1
fi
echo "[AurionOS] isolinux.bin successfully verified."
EOF
fi

lb build 2>&1 | tee "$OUTPUT_DIR/build.log" || warn "lb build exited with errors (checking if ISO was produced anyway)"

# --- Move output ---
if ls "$BUILD_DIR"/*.iso 1>/dev/null 2>&1; then
    mv "$BUILD_DIR"/*.iso "$OUTPUT_DIR/$ISO_NAME.iso"
    ISO_SIZE=$(du -h "$OUTPUT_DIR/$ISO_NAME.iso" | cut -f1)
    echo ""
    log "╔══════════════════════════════════════════════╗"
    log "║          ISO BUILD COMPLETE                   ║"
    log "╠══════════════════════════════════════════════╣"
    log "║ File: $OUTPUT_DIR/$ISO_NAME.iso"
    log "║ Size: $ISO_SIZE"
    log "╠══════════════════════════════════════════════╣"
    log "║ Boot it in VirtualBox/VMware/QEMU or         ║"
    log "║ flash to USB with:                           ║"
    log "║   sudo dd if=output/$ISO_NAME.iso of=/dev/sdX bs=4M ║"
    log "╚══════════════════════════════════════════════╝"
else
    fail "ISO build failed. Check $OUTPUT_DIR/build.log"
fi
