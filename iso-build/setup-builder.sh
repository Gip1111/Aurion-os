#!/bin/bash
# ============================================================
# AurionOS Build Machine Setup
# ============================================================
# Run this ONCE on the machine that will BUILD the ISO.
# This is NOT the AurionOS system — this is the builder.
#
# Supports: Ubuntu 24.04 VM, VPS, or GitHub Actions runner.
#
# Usage: sudo ./iso-build/setup-builder.sh
# ============================================================

set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo $0"; exit 1; }

echo "=== AurionOS Build Machine Setup ==="

apt update -qq
apt install -y -qq \
    live-build \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    grub-pc-bin \
    syslinux-utils \
    isolinux \
    mtools \
    dosfstools \
    build-essential \
    cmake \
    pkg-config \
    git \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-wayland-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    libdbus-1-dev \
    libgl-dev \
    python3 \
    python3-pip \
    python3-venv

# Rust (for non-root user)
if [ -n "${SUDO_USER:-}" ]; then
    if [ ! -f "/home/$SUDO_USER/.cargo/bin/cargo" ]; then
        echo "Installing Rust for user $SUDO_USER..."
        sudo -u "$SUDO_USER" bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet'
    fi
fi

echo ""
echo "=== Build machine ready ==="
echo "Next: sudo ./iso-build/build-iso.sh"
