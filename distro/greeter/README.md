# AurionOS Greeter

## Strategy (MVP)

Use **greetd** as the login daemon with a **Qt-based greeter** (QtGreet or similar) as the display frontend.

### Why not build from scratch?
- Building a fully custom Wayland greeter is a significant effort
- QtGreet provides a working Qt/QML foundation we can brand
- Faster to MVP; we can replace it later when the shell is mature

### Branding Applied
- Custom background: deep dark (#0A0E1A) with subtle aurora gradient
- Aurion logo centered above the login form
- Inter font for all text
- Accent color (#6366F1) for focus states and buttons
- Clock display above the auth card

### greetd Configuration

```toml
# /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "qtgreet"  # or custom greeter binary
user = "greeter"
```

### Session File

The AurionOS session is registered at:
`/usr/share/wayland-sessions/aurion.desktop`

```ini
[Desktop Entry]
Name=AurionOS
Comment=AurionOS Desktop Session
Exec=aurion-session
Type=Application
DesktopNames=AurionOS
```

### aurion-session script

```bash
#!/bin/bash
# Start AurionOS desktop session

# Set environment
export XDG_CURRENT_DESKTOP=AurionOS
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland

# Start system services
systemctl --user start aurion-ai.service &

# Start compositor + shell
labwc &
sleep 0.5
aurion-shell &

# Wait for compositor to exit
wait
```
