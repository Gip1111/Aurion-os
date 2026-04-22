# AurionOS Settings App

> Planned for v0.3+. Not part of MVP.

## Concept

A Qt6/QML settings application replacing GNOME Settings with:
- Search-first navigation
- Categorized panels: Display, Network, Sound, Bluetooth, Users, Updates, AI, Hardware, Privacy
- "Explain" button on every setting (calls AI service)
- Consistent with Aurion design system

## Architecture

- Qt6/QML frontend
- D-Bus backend for system operations (via polkit for privileged actions)
- Reads/writes standard Linux config (NetworkManager, PipeWire, systemd, etc.)
- AI integration via org.aurion.AI D-Bus service
