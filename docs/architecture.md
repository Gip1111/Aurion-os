# AurionOS — Architecture

> This document distinguishes **Prototype**, **MVP**, and **Long-term** choices throughout.

## System Layers

```
┌─────────────────────────────────────────────────────────┐
│                    USER EXPERIENCE                       │
│  Shell (Qt6/QML) · AI Sidebar · Launcher · Dock         │
├─────────────────────────────────────────────────────────┤
│                    SHELL PROTOCOL                        │
│  wlr-layer-shell · xdg-shell · wlr-foreign-toplevel     │
├─────────────────────────────────────────────────────────┤
│                    COMPOSITOR                            │
│  [MVP] labwc (wlroots/C)                                │
│  [Long-term] Evaluate Smithay (Rust) when justified      │
├─────────────────────────────────────────────────────────┤
│                    SYSTEM SERVICES                       │
│  aurion-ai (Python/D-Bus) · aurion-hwcompat (Rust/D-Bus)│
│  aurion-diag (Rust) · aurion-rollback (Rust/Btrfs)      │
├─────────────────────────────────────────────────────────┤
│                    BASE SYSTEM                           │
│  Ubuntu 24.04 LTS · kernel 6.8+ · systemd · PipeWire   │
│  Mesa · NetworkManager · linux-firmware · fwupd          │
└─────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Compositor Layer

**MVP: labwc**
- wlroots-based stacking compositor
- Configured via `~/.config/labwc/rc.xml`
- Provides: window management, output management, xdg-shell, wlr-layer-shell
- AurionOS session registered as a custom Wayland session in `/usr/share/wayland-sessions/`

**Long-term: Smithay evaluation**
- Only pursue when: labwc limits custom UX requirements (animations, transitions, per-window effects)
- COSMIC desktop has proven Smithay viable for production
- Migration path: shell QML stays the same, only compositor binary changes

### 2. Shell Layer (Qt6/QML)

All shell components are Qt6/QML applications using `wlr-layer-shell` to position themselves:

| Component | Layer | Anchor | Behavior |
|-----------|-------|--------|----------|
| TopBar | overlay | top | Persistent, always visible |
| Dock | bottom | bottom | Auto-hide optional, persistent default |
| Launcher | overlay | center | Triggered by Super key, dismissible |
| AISidebar | overlay | right | Triggered by Super+A, slide-in panel |

**Communication:** Shell components talk to system services via D-Bus.

**Process model:** Single `aurion-shell` process hosts all QML components as separate windows. This allows shared state (theme, AI connection, notifications) without IPC overhead.

### 3. AI Service

```
aurion-ai (systemd user service)
├── D-Bus interface: org.aurion.AI
├── Provider abstraction layer
│   ├── OllamaProvider (default, local)
│   ├── [future] LlamaCppProvider
│   └── [future] CloudProvider (opt-in, disabled by default)
├── Context providers
│   ├── LogContext — reads journalctl, dmesg
│   ├── HardwareContext — queries aurion-hwcompat via D-Bus
│   └── SystemContext — uptime, disk, memory, network state
└── Prompt templates
    ├── diagnose — "Why is X not working?"
    ├── explain — "What does this setting do?"
    └── fix_proposal — "How to fix this? (safe proposal)"
```

**Provider abstraction:** All LLM calls go through an abstract `LLMProvider` interface. Provider selection is config-driven (`/etc/aurion/ai.toml`). Cloud providers require explicit user opt-in and are never enabled by default.

### 4. Hardware Compatibility Service

```
aurion-hwcompat (systemd system service, Rust)
├── D-Bus interface: org.aurion.HardwareCompat
├── Scanner
│   ├── sysfs /sys/bus/{pci,usb,...}/devices/
│   ├── modalias extraction
│   ├── lspci / lsusb parsed output
│   └── fwupd integration (firmware update status)
├── Classifier
│   ├── GPU, Network, Audio, Storage, Input, Bluetooth, ...
│   └── Status: Working | Degraded | NotWorking | Unknown
├── Driver Matcher
│   ├── Check loaded modules vs expected
│   ├── Check ubuntu-drivers for available proprietary drivers
│   └── Flag missing firmware from dmesg
└── Device DB
    └── Known quirks, workarounds, escalation categories
```

**Escalation categories:**
1. Standard driver available → auto-suggest install
2. Firmware missing → link to source or explain
3. Quirk/fix possible → propose config change
4. Userspace workaround → explain steps
5. VM/passthrough recommended → explain why
6. Likely requires reverse engineering → document status

### 5. Diagnostics & Rollback

```
aurion-diag (CLI + D-Bus, Rust)
├── Log collector
│   ├── journalctl structured export
│   ├── dmesg ring buffer
│   ├── Xwayland/Wayland logs
│   └── hardware-compat report
├── Snapshot manager (Btrfs)
│   ├── Create snapshot before: updates, driver installs, AI fixes
│   ├── List snapshots with timestamps and descriptions
│   └── Restore to snapshot
├── Changelog
│   ├── /var/log/aurion/changelog.json
│   ├── Records: package installs, config changes, driver changes
│   └── Each entry: timestamp, action, source (user/AI/system), reversible?
└── Rollback
    ├── CLI: aurion-rollback list | restore <id>
    └── GUI integration via D-Bus (future)
```

### 6. ISO Build Pipeline

**Prototype/MVP:** Cubic
- Take Ubuntu 24.04 LTS desktop ISO
- chroot: install aurion packages, remove GNOME branding, configure labwc session
- Output: bootable ISO for VM testing

**Production (planned):**
- `live-build` or `debootstrap` based
- Fully scripted, reproducible
- CI/CD pipeline: commit → build ISO → test in VM → publish
- Package lists and config structured to be Cubic-independent

### 7. Login

**MVP:** greetd + QtGreet
- greetd: minimal login daemon, session-agnostic
- QtGreet: Qt-based greeter — apply Aurion branding (background, colors, logo, fonts)
- Session selector: AurionOS (labwc) as default

**Long-term:** Custom QML greeter with ambient animations, weather, AI status

## D-Bus Interfaces

```
org.aurion.AI
  ├── Ask(context: string, question: string) → string
  ├── DiagnoseDevice(device_id: string) → string
  ├── ExplainSetting(setting_path: string) → string
  └── ProposeFix(issue_id: string) → FixProposal

org.aurion.HardwareCompat
  ├── ScanAll() → DeviceReport[]
  ├── GetDevice(device_id: string) → DeviceInfo
  ├── GetDriverStatus(device_id: string) → DriverStatus
  └── GetFirmwareStatus(device_id: string) → FirmwareStatus

org.aurion.Diagnostics
  ├── CollectLogs(scope: string) → LogBundle
  ├── CreateSnapshot(description: string) → SnapshotId
  ├── ListSnapshots() → Snapshot[]
  └── Rollback(snapshot_id: string) → Result
```

## Security & Safety Principles

1. **No destructive action without user review** — AI proposes, user confirms
2. **All system modifications logged** — `/var/log/aurion/changelog.json`
3. **Snapshot before change** — automatic Btrfs snapshot before any driver/config modification
4. **Rollback always available** — any logged change can be reversed
5. **Cloud AI disabled by default** — no data leaves the machine unless user opts in
6. **Least privilege** — AI service runs as user, hardware service runs with minimal caps
