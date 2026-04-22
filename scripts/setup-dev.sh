#!/bin/bash
# AurionOS Development Environment Setup
# Run this on an Ubuntu 24.04 LTS machine to set up the dev environment.

set -euo pipefail

echo "=== AurionOS Development Environment Setup ==="
echo ""

# --- System packages ---
echo "[1/6] Installing system packages..."
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    pkg-config \
    git \
    curl \
    wget \
    labwc \
    greetd \
    foot \
    wl-clipboard \
    wlr-randr \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-wayland-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-layouts \
    libdbus-1-dev \
    python3 \
    python3-pip \
    python3-venv \
    btrfs-progs \
    flatpak \
    fonts-inter \
    fonts-jetbrains-mono

# --- Layer shell Qt ---
echo "[2/6] Installing layer-shell-qt..."
# layer-shell-qt may need to be built from source or installed from PPA
# Check if available in repos first
if apt-cache show layer-shell-qt6 &>/dev/null; then
    sudo apt install -y layer-shell-qt6
else
    echo "WARNING: layer-shell-qt6 not in repos. You may need to build from source."
    echo "See: https://invent.kde.org/libraries/layer-shell-qt"
fi

# --- Rust toolchain ---
echo "[3/6] Setting up Rust toolchain..."
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
rustup default stable
rustup update

# --- Python environment ---
echo "[4/6] Setting up Python environment for AI service..."
cd ai-services
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev,ollama]"
deactivate
cd ..

# --- Ollama ---
echo "[5/6] Installing Ollama..."
if ! command -v ollama &>/dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
fi
echo "Pulling default AI model (phi3:mini)..."
ollama pull phi3:mini || echo "WARNING: Could not pull model. Ensure Ollama is running."

# --- Flatpak ---
echo "[6/6] Setting up Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Build hardware-compat:  cd hardware-compat && cargo build"
echo "  2. Build diagnostics:      cd diagnostics && cargo build"
echo "  3. Build shell:            cd shell && mkdir build && cd build && cmake .. && make"
echo "  4. Run AI service:         cd ai-services && source .venv/bin/activate && aurion-ai"
echo "  5. Test in labwc:          labwc &"
