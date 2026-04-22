# AurionOS — App Installation UX Plan

## Principle: No Terminal Required

Normal users should **never need a terminal** to install, update, or remove applications.

## Aurion Store

### Concept
A first-class graphical app store that unifies all installation sources into one clean interface.

### MVP (v0.3)
- Qt6/QML application
- Flatpak-first: Flathub as the primary app catalog
- Search, browse by category, one-click install
- Shows app descriptions, screenshots, ratings from Flathub metadata
- Update all button (Flatpak + system updates)

### Architecture
```
┌──────────────────────────────────────┐
│         Aurion Store (Qt6/QML)       │
├──────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────┐│
│  │ Flatpak  │ │  APT     │ │ .deb ││
│  │ Backend  │ │  Backend │ │ file ││
│  └──────────┘ └──────────┘ └──────┘│
├──────────────────────────────────────┤
│  PackageKit D-Bus interface          │
│  (or direct libflatpak / apt calls)  │
└──────────────────────────────────────┘
```

### One-Click Install Flow

1. User searches "Firefox" in Aurion Store
2. Store shows Flatpak (Flathub) result as primary
3. User clicks "Install"
4. Progress bar shows download/install
5. App appears in launcher immediately
6. Done. No terminal. No confirmation dialogs beyond the install click.

### Source Priority

| Priority | Source | Use Case |
|----------|--------|----------|
| 1 | **Flatpak (Flathub)** | All third-party GUI apps |
| 2 | **APT (Ubuntu repos)** | System tools, CLI utilities, libraries |
| 3 | **Snap (optional)** | Only if user explicitly installs snap apps |

## File-Based Installation

### .flatpakref Files
- Double-click → Aurion Store opens → shows app info → "Install" button
- Handled by registering Aurion Store as the default handler for `.flatpakref`

### .deb Files
- Double-click → Aurion Store opens → shows package info and dependencies
- Warning if package conflicts with existing packages
- "Install" button with polkit authentication prompt
- Snapshot created before installation (if Btrfs)
- Uses `apt` or `dpkg` under the hood

### AppImage Files
- Double-click → prompt: "Run this application?" with security notice
- Optional: "Add to launcher" checkbox
- AppImages are NOT installed — they run directly
- Aurion Store can track running AppImages and offer to create launcher entries

### Drag-and-Drop
- Drag a .deb / .flatpakref / .appimage onto the Aurion Store window → starts install flow

## Update Management

### Aurion Update Manager
- Lives in the top bar as a notification badge (dot on the tray)
- Click → shows available updates grouped by source:
  - System updates (apt)
  - App updates (Flatpak)
  - Firmware updates (fwupd)
- "Update All" button
- Automatic Btrfs snapshot before any update batch
- Background check every 6 hours (configurable)

### Security Updates
- `unattended-upgrades` handles critical apt security patches
- User gets a notification after auto-update: "Security updates applied. Snapshot created."

## UX Principles

1. **Search is primary** — don't make users browse categories to find apps
2. **Flatpak is transparent** — don't show "Flatpak" in the UI; just show the app
3. **No jargon** — "Install" not "Deploy"; "Update" not "Upgrade"; "Remove" not "Purge"
4. **AI-enhanced** — "Install a video editor" in launcher → AI suggests apps
5. **Rollback-aware** — system knows what was installed and can undo it
6. **Progress is clear** — download size, install progress, completion notification

## Implementation Timeline

| Phase | Deliverable |
|-------|------------|
| v0.1 | No store — apps via terminal or pre-installed |
| v0.2 | Flatpak CLI integration via launcher ("Install Firefox" → runs flatpak install) |
| v0.3 | Aurion Store MVP — Flatpak search, browse, one-click install |
| v0.4 | .deb and AppImage handling, Update Manager |
| v0.5 | AI-enhanced search, drag-and-drop install |
