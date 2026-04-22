# AurionOS Alpha ISO v0.1 — Build Plan

## What This Produces

A **bootable ISO file** (`aurion-os-0.1-alpha-amd64.iso`) that:
- Boots directly into a branded AurionOS live session
- Runs the Aurion Shell on labwc (not GNOME, not KDE)
- Includes a graphical installer (Calamares) to install to disk
- After install, reboots into AurionOS — no Ubuntu visible anywhere

## Build Architecture

```
You (on any machine)
  │
  │  push code to repo
  ▼
Build Machine (any Ubuntu 24.04 system)
  │
  │  ./iso-build/build-iso.sh
  │  uses live-build to create the ISO
  ▼
aurion-os-0.1-alpha-amd64.iso  (output file, ~2-3 GB)
  │
  │  flash to USB / boot in VM
  ▼
AurionOS Live Session → Install → Reboot → AurionOS
```

The build machine is NOT the product. It's a throwaway builder.
The ISO is the product.

## Build Machine Options

| Option | Effort | Speed |
|--------|--------|-------|
| Any Ubuntu 24.04 VM (VirtualBox, etc.) | Low | ~15 min build |
| GitHub Actions (free tier) | Zero after setup | ~20 min build |
| Cheap VPS (Hetzner, DigitalOcean) | Low | ~10 min build |
| WSL2 on Windows | Medium (may have issues) | Untested |

## Boot Flow

```
Power on
  → GRUB (AurionOS branding, dark theme)
    → Linux kernel 6.8
      → Plymouth (Aurion logo, pulse animation)
        → greetd + auto-login (live session)
          → aurion-session
            → labwc compositor
              → swaybg (dark wallpaper)
              → aurion-shell (TopBar, Dock, Launcher, AI Sidebar)
              → aurion-ai service (mock mode)
```

## Live Session

- Auto-login, no password
- Aurion Shell starts immediately
- Dock includes "Install AurionOS" icon → launches Calamares
- Hardware scanner runs on boot, results available in AI sidebar
- Mock AI by default (Ollama optional post-install)

## Installer (Calamares)

Calamares steps (AurionOS branded):
1. Welcome — "Welcome to AurionOS"
2. Location — timezone picker
3. Keyboard — layout selection
4. Partitions — Btrfs default, auto or manual
5. Users — name, password
6. Summary — review
7. Install — progress bar
8. Finish — "Reboot into AurionOS"

## ISO Contents

| Component | Source | How it gets in |
|-----------|--------|----------------|
| Base system | Ubuntu 24.04 (debootstrap) | live-build |
| Kernel | linux-image-generic (6.8) | live-build |
| Compositor | labwc (apt) | package list |
| Shell | aurion-shell (pre-built binary) | includes.chroot |
| AI service | aurion_ai (Python) | includes.chroot |
| Hardware scanner | aurion-hwcompat (pre-built) | includes.chroot |
| Diagnostics | aurion-diag (pre-built) | includes.chroot |
| Installer | calamares (apt) | package list |
| Plymouth | aurion theme | includes.chroot |
| Greeter | greetd + auto-login config | includes.chroot |
| Session | aurion.desktop + aurion-session | includes.chroot |
| labwc config | rc.xml, autostart, environment | includes.chroot (skel) |
| Fonts | Inter, JetBrains Mono | package list |
| Wallpaper | solid color (MVP) | includes.chroot |

## Milestone: "AurionOS Alpha ISO v0.1"

### Included
- [x] Bootable live ISO from USB or VM
- [x] Aurion boot splash (Plymouth)
- [x] Auto-login to live session
- [x] labwc Wayland session
- [x] TopBar, Dock, Launcher, AI Sidebar
- [x] Mock AI responses
- [x] Hardware scanner CLI
- [x] Diagnostics CLI
- [x] Calamares installer (branded)
- [x] Install to disk with Btrfs default
- [x] Reboot into installed AurionOS

### Not included in v0.1
- Custom logo artwork
- Advanced theme polish
- App store
- Real Ollama AI (post-install optional)
- Custom file manager
- Settings app
