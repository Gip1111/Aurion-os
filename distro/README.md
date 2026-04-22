# AurionOS — Distro Build Configuration

## Build Strategy

### Prototype / MVP: Cubic
Use Cubic to remaster the Ubuntu 24.04 LTS desktop ISO:
1. Remove GNOME branding and unwanted packages (see remove-packages.list)
2. Install Aurion packages (see packages.list)
3. Configure labwc as default session
4. Apply branding (Plymouth, greeter, wallpaper, themes)
5. Set up default user config via /etc/skel

### Production (planned): live-build / debootstrap
- Fully scripted, reproducible builds
- All package lists and config in this directory
- CI/CD: commit → build → test in VM → publish
- No Cubic-specific logic in the OS itself

## Directory Contents

```
distro/
├── packages.list          # Packages to install
├── remove-packages.list   # Packages to remove from base
├── plymouth-theme/        # Boot splash theme
├── greeter/               # Login greeter branding
├── gtk-theme/             # GTK4 dark theme
├── qt-theme/              # Qt6 theme integration
├── skel/                  # Default user config (~/)
└── wayland-sessions/      # Session desktop file
```

## Quick Start (Cubic)

1. Download Ubuntu 24.04 LTS desktop ISO
2. Install Cubic: `sudo apt install cubic`
3. Create a new Cubic project pointing to the ISO
4. In the chroot, run:
   ```bash
   # Remove unwanted packages
   xargs apt remove -y < /path/to/remove-packages.list
   # Install required packages
   xargs apt install -y < /path/to/packages.list
   # Copy branding files
   # Configure default session
   ```
5. Build the ISO
