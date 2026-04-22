# AurionOS

> **Working name.** Final branding not locked.

An AI-first Linux distribution built on Ubuntu 24.04 LTS with an original desktop experience, intelligent hardware compatibility, and safety-first system automation.

---

## What is AurionOS?

AurionOS is a next-generation Linux OS that replaces the entire user-facing experience of Ubuntu with:

- **An original desktop shell** — not GNOME, not KDE, not a theme. A new Qt6/QML-based shell running on a Wayland compositor.
- **AI-integrated system intelligence** — an assistant that understands your hardware, reads your logs, explains errors in plain language, and proposes safe fixes.
- **Hardware compatibility intelligence** — proactive device detection, driver matching, firmware status, and guided resolution for problematic hardware.
- **Safety-first automation** — every system change is proposed, reviewed, and reversible via Btrfs snapshots.

## Architecture Overview

```
┌──────────────────────────────────────────────┐
│            Aurion Shell (Qt6/QML)             │
│  Top Bar │ Dock │ Launcher │ AI Sidebar       │
├──────────────────────────────────────────────┤
│  wlr-layer-shell protocol                    │
├──────────────────────────────────────────────┤
│  labwc compositor (wlroots)                   │
├──────────────────────────────────────────────┤
│  Aurion AI Service     │ Hardware Compat Svc  │
│  (Python, D-Bus)       │ (Rust, D-Bus)        │
├──────────────────────────────────────────────┤
│  Diagnostics & Rollback (Rust)               │
├──────────────────────────────────────────────┤
│  Ubuntu 24.04 LTS base                       │
│  kernel · systemd · apt · PipeWire · Mesa    │
└──────────────────────────────────────────────┘
```

## Repository Structure

```
aurion-os/
├── shell/              # Qt6/QML desktop shell (top bar, dock, launcher, AI sidebar)
├── ai-services/        # AI assistant service (Python, provider-agnostic)
├── hardware-compat/    # Hardware scanner and compatibility engine (Rust)
├── diagnostics/        # Log collection, snapshots, rollback (Rust)
├── settings/           # Settings/control center app (Qt6/QML) — future
├── distro/             # ISO build config, themes, greeter, skel
├── installer/          # Installer config (Calamares) — future
├── branding/           # Visual identity: colors, typography, logo spec
├── design-system/      # Design tokens, component specs, patterns
├── docs/               # Architecture, product vision, roadmap
└── scripts/            # Build, dev setup, and testing scripts
```

## Tech Stack

| Component | Technology | Phase |
|-----------|------------|-------|
| Compositor | labwc (wlroots) | MVP |
| Shell UI | Qt6 / QML + wlr-layer-shell | MVP |
| AI service | Python 3.12 + Ollama | MVP |
| Hardware scanner | Rust | MVP |
| Diagnostics/rollback | Rust + Btrfs | MVP |
| Login | greetd + QtGreet (branded) | MVP |
| ISO build | Cubic | Prototype |
| ISO build | live-build / debootstrap | Production |
| Future compositor | Smithay (Rust) — evaluate when justified | Long-term |

## MVP Scope (v0.1)

- Bootable Ubuntu 24.04 LTS branded remix
- Custom login experience (greetd + branded greeter)
- labwc Wayland session
- Original top bar, dock, and launcher
- AI sidebar with system context awareness
- Hardware compatibility scanner
- Basic diagnostics collector
- Btrfs snapshot/rollback foundation
- Original visual identity (theme, Plymouth, wallpaper)

## Development

### Prerequisites

- Ubuntu 24.04 LTS (or compatible) development machine
- Qt6 development libraries (`qt6-declarative-dev`, `qt6-wayland-dev`)
- Rust toolchain (`rustup`)
- Python 3.12+
- labwc compositor
- Ollama (for AI service development)

### Quick Start

```bash
# Clone the repository
git clone <repo-url> aurion-os
cd aurion-os

# Run the dev environment setup
./scripts/setup-dev.sh
```

See [docs/architecture.md](docs/architecture.md) for detailed technical documentation.

## License

GPL-3.0 — see [LICENSE](LICENSE).
