# AurionOS — VM Setup & Testing Guide

## Prerequisites

- VirtualBox, VMware, or QEMU/KVM
- Ubuntu 24.04 LTS desktop ISO
- At least 4GB RAM, 2 CPUs, 40GB disk for the VM
- Host machine with the AurionOS repo cloned

## Step 1: Create the VM

```bash
# QEMU example (adjust for your hypervisor):
qemu-img create -f qcow2 aurion-dev.qcow2 40G
qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 2 \
  -drive file=aurion-dev.qcow2,format=qcow2 \
  -cdrom ubuntu-24.04-desktop-amd64.iso \
  -boot d -vga virtio
```

For **VirtualBox**: create a new Ubuntu 24.04 VM, enable EFI, set 4GB RAM, enable 3D acceleration.

## Step 2: Install Ubuntu 24.04

Install Ubuntu normally. During setup:
- **Filesystem:** Choose Btrfs if available (for snapshot testing). If the installer doesn't offer Btrfs, use ext4 and switch later.
- **User:** Create user `aurion` (or any name)
- **Minimal install** is sufficient

## Step 3: Install Dependencies

After first boot, copy the repo into the VM and run:

```bash
# Copy repo into VM (via shared folder, scp, or git clone)
cd ~/aurion-os

# Run dev setup (installs everything)
chmod +x scripts/setup-dev.sh
./scripts/setup-dev.sh
```

This installs: labwc, greetd, Qt6, Rust, Python venv, Ollama, fonts, etc.

## Step 4: Build the Shell

```bash
cd ~/aurion-os/shell
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo cp aurion-shell /usr/local/bin/
```

If `layer-shell-qt` is not found, the shell builds in **dev mode** (regular windows instead of layer-shell surfaces). It still works for testing UI.

## Step 5: Build Hardware Scanner

```bash
cd ~/aurion-os/hardware-compat
cargo build --release
sudo cp target/release/aurion-hwcompat /usr/local/bin/

# Test it:
aurion-hwcompat --scan
aurion-hwcompat --scan --json
```

## Step 6: Build Diagnostics

```bash
cd ~/aurion-os/diagnostics
cargo build --release
sudo cp target/release/aurion-diag /usr/local/bin/

# Test it:
aurion-diag help
sudo aurion-diag collect-logs
```

## Step 7: Install AI Service

```bash
cd ~/aurion-os/ai-services
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Copy config
mkdir -p ~/.config/aurion
cp config/ai.toml ~/.config/aurion/ai.toml

# Install systemd service
mkdir -p ~/.config/systemd/user
cp systemd/aurion-ai.service ~/.config/systemd/user/
systemctl --user daemon-reload
```

## Step 8: Test the AI Service

```bash
# Start in foreground (mock mode — no Ollama needed):
python -m aurion_ai.service

# You'll get a REPL if D-Bus isn't available:
# aurion-ai> Check my hardware
# (canned response from mock provider)
```

To switch to Ollama:
```bash
# Edit config:
nano ~/.config/aurion/ai.toml
# Change: provider = "ollama"

# Make sure Ollama is running:
systemctl start ollama
ollama pull phi3:mini
```

## Step 9: Install Session Files

```bash
# Copy session config
cp -r ~/aurion-os/distro/skel/.config/labwc ~/.config/labwc
sudo cp ~/aurion-os/distro/bin/aurion-session /usr/local/bin/
sudo chmod +x /usr/local/bin/aurion-session
sudo cp ~/aurion-os/distro/wayland-sessions/aurion.desktop /usr/share/wayland-sessions/

# Install swaybg for wallpaper
sudo apt install swaybg
```

## Step 10: Test the Shell Session

### Option A: Inside existing GNOME session (quick test)
```bash
# Open a terminal and run the shell directly on your existing Wayland:
aurion-shell
# This opens shell windows as regular floating windows (dev mode)
```

### Option B: Full labwc session (real test)
```bash
# From a TTY (Ctrl+Alt+F3), or after setting up greetd:
aurion-session
# This starts labwc + aurion-shell with layer-shell surfaces
```

### Option C: Nested Wayland (best for development)
```bash
# Run labwc nested inside GNOME:
labwc -s "aurion-shell"
# This opens a labwc window with the full AurionOS shell inside it
```

**Recommended for development: Option C** — gives you a real labwc+shell environment inside a window.

## Step 11: Test Keyboard Shortcuts

Once in a labwc session:
- `Super+Space` → Toggle launcher
- `Super+A` → Toggle AI sidebar
- `Super+Return` → Open terminal (foot)
- `Alt+F4` → Close window
- `Super+Left/Right` → Switch workspace

## Step 12: Test Snapshots (requires Btrfs)

```bash
# Only works if root is on Btrfs:
sudo aurion-diag snapshot "before testing"
sudo aurion-diag snapshots
# sudo aurion-diag rollback <snapshot-id>  # careful!
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Shell windows appear but no layer-shell | Install `layer-shell-qt` from KDE repos or build from source |
| D-Bus errors in shell | Start AI service: `systemctl --user start aurion-ai` |
| labwc won't start | Check `~/.config/labwc/rc.xml` for syntax errors |
| No wallpaper | Install swaybg: `sudo apt install swaybg` |
| AI gives mock responses | Change `provider = "ollama"` in `~/.config/aurion/ai.toml` |
