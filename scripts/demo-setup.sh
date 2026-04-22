#!/bin/bash
# ============================================================
# AurionOS Demo Setup — Run this ONCE on a fresh Ubuntu 24.04
# ============================================================
# This script installs every dependency needed to build and
# run the AurionOS demo. It is safe to re-run.
#
# Usage: chmod +x scripts/demo-setup.sh && ./scripts/demo-setup.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

# Must run on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    fail "This script requires Ubuntu 24.04. Detected: $(cat /etc/os-release | head -1)"
fi

log "=== AurionOS Demo Setup ==="
log "This will install all dependencies. Takes ~5 minutes."
echo ""

# --- 1. System packages ---
log "Installing system packages..."
sudo apt update -qq
sudo apt install -y -qq \
    build-essential cmake pkg-config git curl wget \
    qt6-base-dev qt6-declarative-dev qt6-wayland-dev \
    qml6-module-qtquick qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    qt6-tools-dev-tools \
    libdbus-1-dev \
    libgl-dev \
    labwc swaybg foot \
    python3 python3-pip python3-venv \
    fonts-inter \
    wl-clipboard \
    2>&1 | tail -1

log "System packages installed ✓"

# --- 2. Rust toolchain ---
if command -v rustc &>/dev/null; then
    log "Rust already installed ($(rustc --version)) ✓"
else
    log "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet
    source "$HOME/.cargo/env"
    log "Rust installed ✓"
fi

# --- 3. Python venv for AI service ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log "Setting up Python environment..."
cd "$REPO_DIR/ai-services"
python3 -m venv .venv
source .venv/bin/activate
pip install -q -e "." 2>&1 | tail -1
deactivate
log "Python AI service installed ✓"

# --- 4. Create default config ---
mkdir -p ~/.config/aurion
if [ ! -f ~/.config/aurion/ai.toml ]; then
    cp "$REPO_DIR/ai-services/config/ai.toml" ~/.config/aurion/ai.toml
    log "AI config created at ~/.config/aurion/ai.toml ✓"
else
    log "AI config already exists ✓"
fi

# --- 5. Copy labwc config ---
mkdir -p ~/.config/labwc
cp "$REPO_DIR/distro/skel/.config/labwc/rc.xml" ~/.config/labwc/rc.xml
cp "$REPO_DIR/distro/skel/.config/labwc/autostart" ~/.config/labwc/autostart
cp "$REPO_DIR/distro/skel/.config/labwc/environment" ~/.config/labwc/environment
log "labwc config installed ✓"

echo ""
log "=== Setup Complete ==="
log "Next: run ./scripts/demo-build.sh"
