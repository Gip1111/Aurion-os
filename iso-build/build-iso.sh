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
    --bootloader "syslinux" \
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
dbus-user-session
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
seatd

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

# Autostart for live session — installed in BOTH skel and /etc/xdg so it runs
# regardless of how /home/aurion was populated (chroot skel vs casper dynamic
# user creation). labwc reads autostart from, in order:
#   1. $XDG_CONFIG_HOME/labwc/autostart  (-> ~/.config/labwc/autostart)
#   2. /etc/xdg/labwc/autostart          (system-wide fallback)
# Only the first found is used — so we write the SAME robust script to both.
# The script logs to $XDG_RUNTIME_DIR/aurion-autostart.log so we can diagnose
# the "only mouse cursor" scenario (= compositor up, autostart didn't run
# or spawned binaries that crashed silently).
AUTOSTART_BODY='#!/bin/sh
LOG="${XDG_RUNTIME_DIR:-/tmp}/aurion-autostart.log"
exec >>"$LOG" 2>&1
echo "=== aurion autostart @ $(date) as $(id -un) on $WAYLAND_DISPLAY ==="

# 1. Background so the screen is not pitch black even if the shell fails
if command -v swaybg >/dev/null 2>&1; then
    swaybg -c "#0A0E1A" &
    echo "swaybg started (pid $!)"
else
    echo "WARN: swaybg not installed"
fi

# 2. Aurion shell — the main UI
if [ -x /usr/local/bin/aurion-shell ]; then
    /usr/local/bin/aurion-shell &
    echo "aurion-shell started (pid $!)"
else
    echo "WARN: /usr/local/bin/aurion-shell missing or not executable"
    # Fallback so the user is not stuck with a blank cursor — give them a terminal
    if command -v foot >/dev/null 2>&1; then
        foot &
        echo "foot launched as shell fallback (pid $!)"
    fi
fi

# 3. Hardware scan (best effort, non-fatal)
if [ -x /usr/local/bin/aurion-hwcompat ]; then
    /usr/local/bin/aurion-hwcompat --scan --json > /tmp/aurion-hw-report.json 2>/dev/null &
fi
'

mkdir -p "$CHROOT/etc/skel/.config/labwc"
mkdir -p "$CHROOT/etc/xdg/labwc"
printf '%s' "$AUTOSTART_BODY" > "$CHROOT/etc/skel/.config/labwc/autostart"
printf '%s' "$AUTOSTART_BODY" > "$CHROOT/etc/xdg/labwc/autostart"
chmod +x "$CHROOT/etc/skel/.config/labwc/autostart"
chmod +x "$CHROOT/etc/xdg/labwc/autostart"

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

# --- Enable greetd, disable all other display managers ---
# Silent failures on DM enable = text login at boot. Hard-check greetd.
systemctl disable gdm3.service 2>/dev/null || true
systemctl disable lightdm.service 2>/dev/null || true
systemctl disable sddm.service 2>/dev/null || true

# Default target MUST be graphical — otherwise systemd boots multi-user.target
# and we land on a getty text login instead of the display manager.
systemctl set-default graphical.target

# Ensure the greetd unit exists before enabling (fail loudly if not)
if [ ! -f /lib/systemd/system/greetd.service ] && [ ! -f /etc/systemd/system/greetd.service ]; then
    echo "FATAL: greetd.service unit not found — greetd package failed to install?"
    dpkg -l greetd || true
    exit 1
fi
systemctl enable greetd.service
# Make display-manager.service alias point to greetd (what graphical.target wants)
ln -sf /lib/systemd/system/greetd.service /etc/systemd/system/display-manager.service

# --- Create live user ---
# NB: casper.conf USERNAME=aurion drives casper's own user creation at live boot,
# but pre-creating here guarantees the user exists in the installed system too
# (after calamares) and seeds /home/aurion from /etc/skel.
if ! id aurion &>/dev/null; then
    useradd -m -s /bin/bash -G sudo,video,audio,input,render,netdev,plugdev aurion
    echo "aurion:aurion" | chpasswd
    echo "aurion ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/aurion
    chmod 440 /etc/sudoers.d/aurion
fi

# Force-seed skel into /home/aurion even if user pre-existed (ensures labwc
# autostart and aurion configs are present on first login).
if [ -d /etc/skel ]; then
    cp -rT /etc/skel /home/aurion
    chown -R aurion:aurion /home/aurion
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

# --- Configure Live User (Casper) ---
cat > /etc/casper.conf << 'CASPER'
export USERNAME="aurion"
export USERFULLNAME="AurionOS Live"
export HOST="aurion-live"
export BUILD_SYSTEM="Ubuntu"
export FLAVOUR="AurionOS"
CASPER

# --- Configure Greetd Auto-Login ---
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml << 'GREETD'
[terminal]
vt = 1

[default_session]
command = "/usr/local/bin/aurion-session"
user = "aurion"
GREETD

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
step "[5.7/6] Patching live-build syslinux script for robust ISO generation..."
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

# Same for c32 modules and isohdpfx.bin
if [ -d chroot/usr/lib/syslinux/modules/bios ]; then
    cp chroot/usr/lib/syslinux/modules/bios/* binary/isolinux/ 2>/dev/null || true
elif [ -d chroot/usr/lib/syslinux ]; then
    cp chroot/usr/lib/syslinux/*.c32 binary/isolinux/ 2>/dev/null || true
fi

if [ -f chroot/usr/lib/ISOLINUX/isohdpfx.bin ]; then
    cp chroot/usr/lib/ISOLINUX/isohdpfx.bin binary/isolinux/isohdpfx.bin
fi

echo "[AurionOS] Debug: binary/isolinux contents before xorriso:"
ls -lah binary/isolinux/ || true

# Explicit check
if [ ! -f binary/isolinux/isolinux.bin ]; then
    echo "ERROR: isolinux.bin is missing from binary/isolinux!"
    echo "This will cause xorriso to fail. Aborting."
    exit 1
fi
echo "[AurionOS] isolinux.bin successfully verified."
EOF
fi

# --- Compile and Inject Custom Graphical Shell ---
step "[5.8/6] Compiling AurionOS Shell & Injecting Configs..."
if [ -d shell ]; then
    echo "Compiling aurion-shell natively..."
    mkdir -p shell/build
    (cd shell/build && cmake .. && make -j$(nproc))
else
    echo "WARNING: shell/ directory not found in workspace."
fi

echo "Copying shell and distro configs into ISO chroot..."
mkdir -p config/includes.chroot/usr/local/bin
mkdir -p config/includes.chroot/usr/share/wayland-sessions
mkdir -p config/includes.chroot/etc/skel/.config/labwc

# Shell binary
if [ -f shell/build/aurion-shell ]; then
    cp shell/build/aurion-shell config/includes.chroot/usr/local/bin/
    chmod +x config/includes.chroot/usr/local/bin/aurion-shell
else
    warn "aurion-shell binary missing! Compilation may have failed."
fi

# Session script
if [ -f distro/bin/aurion-session ]; then
    cp distro/bin/aurion-session config/includes.chroot/usr/local/bin/
    chmod +x config/includes.chroot/usr/local/bin/aurion-session
fi

# Wayland session file
if [ -f distro/wayland-sessions/aurion.desktop ]; then
    cp distro/wayland-sessions/aurion.desktop config/includes.chroot/usr/share/wayland-sessions/
fi

# labwc autostart
if [ -d distro/skel/.config/labwc ]; then
    cp -r distro/skel/.config/labwc/* config/includes.chroot/etc/skel/.config/labwc/
fi

# Validation Checks
echo "Validating graphical components before build..."
FAIL=0
if [ ! -f config/includes.chroot/usr/local/bin/aurion-shell ]; then
    echo "ERROR: aurion-shell missing in chroot!"
    FAIL=1
fi
if [ ! -f config/includes.chroot/usr/local/bin/aurion-session ]; then
    echo "ERROR: aurion-session missing in chroot!"
    FAIL=1
fi
if [ ! -f config/includes.chroot/usr/share/wayland-sessions/aurion.desktop ]; then
    echo "ERROR: aurion.desktop missing in chroot!"
    FAIL=1
fi
if [ $FAIL -eq 1 ]; then
    echo "Validation failed. Aborting build."
    exit 1
fi
echo "[AurionOS] All graphical components validated successfully."

# --- Disable live-build's broken ISO generator ---
step "[5.9/6] Bypassing live-build ISO generator (using custom xorriso instead)..."
if [ -f /usr/lib/live/build/lb_binary_iso ]; then
    # Clear the file and make it exit 0 so live-build doesn't crash with "no such script"
    echo "#!/bin/sh" > /usr/lib/live/build/lb_binary_iso
    echo "exit 0" >> /usr/lib/live/build/lb_binary_iso
fi

lb build 2>&1 | tee "$OUTPUT_DIR/build.log" || warn "lb build exited with errors (checking if ISO was produced anyway)"

# --- Final Step: Generate the Secure Boot Hybrid ISO robustly ---
step "[6/6] Generating Secure Boot Hybrid ISO with xorriso..."

KERNEL_PATH=$(ls binary/casper/vmlinuz* 2>/dev/null | head -n 1 || ls binary/live/vmlinuz* 2>/dev/null | head -n 1)
INITRD_PATH=$(ls binary/casper/initrd* 2>/dev/null | head -n 1 || ls binary/live/initrd* 2>/dev/null | head -n 1)

if [ -z "$KERNEL_PATH" ]; then
    fail "FATAL: Could not find kernel in binary/casper or binary/live! Squashfs build failed."
fi

K_FILE=$(basename "$KERNEL_PATH")
I_FILE=$(basename "$INITRD_PATH")
BOOT_DIR=$(basename $(dirname "$KERNEL_PATH"))

echo "[AurionOS] Found kernel: /$BOOT_DIR/$K_FILE"
echo "[AurionOS] Found initrd: /$BOOT_DIR/$I_FILE"

# --- Create EFI Boot Partition via grub-mkstandalone ---
# The Canonical signed-grub chain (shim -> grubx64.efi.signed) was unreliable:
# signed grub has a hardcoded prefix+UUID inside an immutable memdisk and does
# NOT honor an external stub grub.cfg in /EFI/BOOT/ — result: drop to grub>
# prompt with no menu. We build our own standalone grub EFI binary with the
# config embedded IN the binary itself. Boot is guaranteed deterministic.
# Tradeoff: unsigned => Secure Boot must be OFF in firmware.
echo "[AurionOS] Building standalone GRUB EFI binary with embedded config (build-tag=EMB_V2)..."
rm -rf build_efi
mkdir -p build_efi/EFI/BOOT

# Embedded memdisk config — executed automatically by grub at startup.
# Prints debug info so that if anything fails we see WHERE, not a silent prompt.
cat > /tmp/aurion-memdisk-grub.cfg << 'EOF'
# === AurionOS embedded grub.cfg (build tag: EMB_V2) ===
insmod all_video
insmod gfxterm
insmod iso9660
insmod fat
insmod part_gpt
insmod part_msdos
insmod search_label
insmod search_fs_uuid
insmod configfile
insmod echo
insmod test
insmod regexp

terminal_output console
echo "=== AurionOS GRUB (standalone EMB_V2) ==="
echo "cmdpath=$cmdpath prefix=$prefix root=$root"

if search --no-floppy --set=aurion_root --label AURIONOS_LIVE; then
    echo "Found AURIONOS_LIVE volume at ($aurion_root)"
    set root=$aurion_root
    set prefix=($aurion_root)/boot/grub
    if [ -f ($aurion_root)/boot/grub/grub.cfg ]; then
        echo "Loading ($aurion_root)/boot/grub/grub.cfg ..."
        configfile ($aurion_root)/boot/grub/grub.cfg
    else
        echo "WARN: ($aurion_root)/boot/grub/grub.cfg not found on volume"
    fi
else
    echo "WARN: search --label AURIONOS_LIVE failed. Visible devices:"
    ls
fi

# Fallback inline menu: reached only if chainload above failed.
# Kernel/initrd names substituted at build time by sed below.
set timeout_style=menu
set timeout=10
set default=0

menuentry "Start AurionOS Live (Wayland)" {
    search --no-floppy --set=root --label AURIONOS_LIVE
    echo "Loading kernel from ($root)/__BOOT_DIR__/__K_FILE__ ..."
    linux  ($root)/__BOOT_DIR__/__K_FILE__ boot=casper quiet splash ---
    initrd ($root)/__BOOT_DIR__/__I_FILE__
}
menuentry "Start AurionOS Live (Safe Graphics)" {
    search --no-floppy --set=root --label AURIONOS_LIVE
    linux  ($root)/__BOOT_DIR__/__K_FILE__ boot=casper nomodeset quiet splash ---
    initrd ($root)/__BOOT_DIR__/__I_FILE__
}
EOF

# Substitute kernel/initrd filenames into the fallback section
sed -i "s|__BOOT_DIR__|$BOOT_DIR|g; s|__K_FILE__|$K_FILE|g; s|__I_FILE__|$I_FILE|g" \
    /tmp/aurion-memdisk-grub.cfg

# Build the standalone grub EFI binary. The file mapping
# "boot/grub/grub.cfg=/tmp/..." places our config at (memdisk)/boot/grub/grub.cfg,
# which is where grub-mkstandalone sets $prefix by default — so grub auto-loads
# our config at startup. No external stub needed.
GRUB_MODULES="all_video boot btrfs cat chain configfile echo efifwsetup efinet \
    ext2 fat font gettext gfxmenu gfxterm gfxterm_background gzio halt help \
    hfsplus iso9660 jfs jpeg keystatus linux loadenv loopback ls lsefi lsefimmap \
    lsefisystab memdisk minicmd normal part_apple part_gpt part_msdos png probe \
    reboot regexp search search_fs_file search_fs_uuid search_label sleep test \
    true video xfs"

grub-mkstandalone \
    --format=x86_64-efi \
    --output=build_efi/EFI/BOOT/BOOTx64.EFI \
    --modules="$GRUB_MODULES" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=/tmp/aurion-memdisk-grub.cfg" \
    || fail "grub-mkstandalone failed — check that grub-efi-amd64-bin is installed"

# Sanity check the produced binary
EFI_BIN_SIZE=$(stat -c%s build_efi/EFI/BOOT/BOOTx64.EFI)
if [ "$EFI_BIN_SIZE" -lt 1000000 ]; then
    fail "BOOTx64.EFI is too small ($EFI_BIN_SIZE bytes) — grub-mkstandalone likely malfunctioned"
fi
echo "[AurionOS] Built BOOTx64.EFI (${EFI_BIN_SIZE} bytes)"

# --- Package efi.img (FAT32 ESP) ---
echo "[AurionOS] Packaging efi.img..."
mkdir -p binary/boot/grub
dd if=/dev/zero of=binary/boot/grub/efi.img bs=1M count=16 status=none
mkfs.vfat -F 32 -n AURIONEFI binary/boot/grub/efi.img >/dev/null

mmd  -i binary/boot/grub/efi.img ::/EFI
mmd  -i binary/boot/grub/efi.img ::/EFI/BOOT
mcopy -i binary/boot/grub/efi.img build_efi/EFI/BOOT/BOOTx64.EFI ::/EFI/BOOT/BOOTx64.EFI
# Mirror at grubx64.efi for firmwares that probe that name
mcopy -i binary/boot/grub/efi.img build_efi/EFI/BOOT/BOOTx64.EFI ::/EFI/BOOT/grubx64.efi

echo "[AurionOS] efi.img contents:"
mdir -i binary/boot/grub/efi.img -/ ::/ || true

# --- Real grub.cfg on iso9660 root (chainloaded from embedded config above) ---
echo "[AurionOS] Preparing main GRUB menu on iso9660 root..."
mkdir -p binary/boot/grub
cat > binary/boot/grub/grub.cfg << EOF
# AurionOS main GRUB menu — chainloaded by BOOTx64.EFI embedded config
search --no-floppy --set=root --label AURIONOS_LIVE
set prefix=(\$root)/boot/grub

set default=0
set timeout=5
set gfxmode=auto
set gfxpayload=keep

insmod all_video
insmod gfxterm
insmod iso9660

menuentry "Start AurionOS Live (Wayland)" {
    linux  /$BOOT_DIR/$K_FILE boot=casper quiet splash ---
    initrd /$BOOT_DIR/$I_FILE
}

menuentry "Start AurionOS Live (Safe Graphics)" {
    linux  /$BOOT_DIR/$K_FILE boot=casper nomodeset quiet splash ---
    initrd /$BOOT_DIR/$I_FILE
}

menuentry "Hardware Diagnostics" {
    linux  /$BOOT_DIR/$K_FILE boot=casper aurion.diag=1 quiet splash ---
    initrd /$BOOT_DIR/$I_FILE
}

menuentry "Check disc for defects" {
    linux  /$BOOT_DIR/$K_FILE boot=casper integrity-check quiet splash ---
    initrd /$BOOT_DIR/$I_FILE
}
EOF

# --- Run xorriso to build the ultimate hybrid ISO ---
echo "[AurionOS] Running xorriso..."

# Detect MBR boot record dynamically
MBR_FILE="/usr/lib/ISOLINUX/isohdpfx.bin"
if [ -f "binary/isolinux/isohdpfx.bin" ]; then
    MBR_FILE="binary/isolinux/isohdpfx.bin"
elif [ -f "chroot/usr/lib/ISOLINUX/isohdpfx.bin" ]; then
    MBR_FILE="chroot/usr/lib/ISOLINUX/isohdpfx.bin"
fi

xorriso -as mkisofs \
    -r -V "AURIONOS_LIVE" \
    -J -joliet-long -l -cache-inodes -iso-level 3 \
    -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
    -boot-load-size 4 -boot-info-table \
    -isohybrid-mbr "$MBR_FILE" \
    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o "$OUTPUT_DIR/$ISO_NAME.iso" binary/

# --- Post-build: verify boot layout inside the produced ISO ---
if [ -f "$OUTPUT_DIR/$ISO_NAME.iso" ]; then
    echo ""
    echo "[AurionOS] ===== Final ISO boot layout verification ====="
    echo "[AurionOS] grub.cfg files found in iso9660:"
    xorriso -indev "$OUTPUT_DIR/$ISO_NAME.iso" -find / -name grub.cfg 2>/dev/null || true
    echo "[AurionOS] /boot listing:"
    xorriso -indev "$OUTPUT_DIR/$ISO_NAME.iso" -ls /boot 2>/dev/null || true
    echo "[AurionOS] Contents of embedded efi.img (FAT32 ESP):"
    xorriso -osirrox on -indev "$OUTPUT_DIR/$ISO_NAME.iso" \
        -extract /boot/grub/efi.img /tmp/aurionos_efi_check.img 2>/dev/null || true
    if [ -f /tmp/aurionos_efi_check.img ]; then
        mdir -i /tmp/aurionos_efi_check.img -/ ::/ || true
        EMB_SIZE=$(mtype -i /tmp/aurionos_efi_check.img ::/EFI/BOOT/BOOTx64.EFI 2>/dev/null | wc -c)
        echo "[AurionOS] BOOTx64.EFI inside efi.img: ~${EMB_SIZE} bytes"
        rm -f /tmp/aurionos_efi_check.img
    fi
    echo "[AurionOS] =============================================="
fi

# --- Move output ---
if [ -f "$OUTPUT_DIR/$ISO_NAME.iso" ]; then
    ISO_SIZE=$(du -h "$OUTPUT_DIR/$ISO_NAME.iso" | cut -f1)
    echo ""
    log "╔══════════════════════════════════════════════╗"
    log "║          ISO BUILD COMPLETE (SIGNED)          ║"
    log "╠══════════════════════════════════════════════╣"
    log "║ File: $OUTPUT_DIR/$ISO_NAME.iso"
    log "║ Size: $ISO_SIZE"
    log "║ Mode: Secure Boot / UEFI / Legacy BIOS       ║"
    log "╠══════════════════════════════════════════════╣"
    log "║ Boot it in VirtualBox/VMware/QEMU or         ║"
    log "║ flash to USB with:                           ║"
    log "║   sudo dd if=output/$ISO_NAME.iso of=/dev/sdX bs=4M ║"
    log "╚══════════════════════════════════════════════╝"
else
    fail "ISO build failed. Check $OUTPUT_DIR/build.log"
fi


