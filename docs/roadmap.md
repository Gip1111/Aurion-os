# AurionOS — Roadmap

## Phase A: MVP (v0.1 – v0.3)

### v0.1 — "First Light"
Core proof of concept. Bootable, branded, functional.

- Bootable ISO from Ubuntu 24.04 LTS (Cubic)
- labwc compositor as default Wayland session
- greetd + branded QtGreet login
- Shell MVP: top bar, dock, launcher overlay
- AI sidebar with basic chat and system context
- Hardware compatibility scanner (device detection + classification)
- Basic diagnostics log collector
- Btrfs snapshot foundation (manual CLI)
- Plymouth boot theme
- GTK/Qt dark theme with Aurion visual identity
- Custom wallpaper set

### v0.2 — "Constellation"
Polish and expand the shell experience.

- Notification center (grouped, actionable)
- Quick settings panel (Wi-Fi, Bluetooth, Volume, Brightness)
- Workspace overview (spatial grid, live previews)
- Improved AI context: hardware diagnostics integration
- Hardware compatibility center: basic GUI
- AI-proposed fixes: first safe automation flows
- Automatic snapshots before system updates

### v0.3 — "Radiance"
Complete the core desktop experience.

- Settings app MVP (display, network, sound, updates, AI config)
- File manager MVP (clean, dual-pane optional)
- System update manager GUI (apt + Flatpak + fwupd)
- Improved hardware scanner: firmware checking, driver recommendations
- AI: explain any setting, diagnose any device
- Theme refinement: animations, transitions, glass effects

## Phase B: Polish (v0.4 – v0.8)

### v0.4 – v0.5
- Custom installer (Calamares-based, branded)
- Migrate ISO build from Cubic to live-build pipeline
- Advanced AI: workflow automation proposals
- Hardware compatibility center: full GUI with fix proposals
- Rollback GUI (browse snapshots, one-click restore)

### v0.6 – v0.8
- OTA update system exploration
- Multi-monitor UX polish
- Accessibility features
- Localization (i18n) foundation
- Community contribution pipeline
- Begin Smithay compositor evaluation

## Phase C: Full Vision (v1.0+)

### v1.0 — "Aurion"
- Production-ready distribution
- Full original desktop experience
- Mature AI assistant with multi-provider support
- Complete hardware compatibility intelligence
- Custom compositor (Smithay) if evaluation justifies migration
- Custom installer
- Reproducible CI/CD build pipeline
- Public release

## Timeline (Estimated)

| Phase | Target | Duration |
|-------|--------|----------|
| v0.1 | Month 1–2 | 8 weeks |
| v0.2 | Month 3–4 | 8 weeks |
| v0.3 | Month 5–6 | 8 weeks |
| v0.4–v0.8 | Month 7–12 | 24 weeks |
| v1.0 | Month 13–18 | 24 weeks |
