# AurionOS — QUICKSTART

## What you need

- A fresh Ubuntu 24.04 LTS VM (VirtualBox, VMware, or QEMU)
- 4 GB RAM, 2 CPUs, 40 GB disk
- Install Ubuntu with defaults (Minimal Install is fine)
- After install, log in and open a terminal

## Step 1: Get the code into the VM

Option A — shared folder:
```
cp -r /media/sf_shared/LINUX\ OS ~/aurion-os
```

Option B — git (if hosted):
```
git clone <your-repo-url> ~/aurion-os
```

Option C — USB/scp/whatever gets the folder there:
```
# Just get the "LINUX OS" folder into ~/aurion-os
```

## Step 2: Setup (run once, ~5 min)

```
cd ~/aurion-os
chmod +x scripts/*.sh
./scripts/demo-setup.sh
```

This installs: Qt6, labwc, Rust, Python venv, fonts, configs.
You only run this once.

## Step 3: Build (run after any code change)

```
./scripts/demo-build.sh
```

This builds: Aurion Shell, Hardware Scanner, Diagnostics.
Takes ~2 min first time, ~10 sec after.

## Step 4: Test (optional, verify everything works)

```
./scripts/demo-test.sh
```

Shows pass/fail for each component.

## Step 5: Run the demo

```
./scripts/demo-run.sh
```

This opens a **window inside your desktop** containing the AurionOS session.

## What you will see

A dark desktop window with:

1. **Top Bar** (top of window) — clock, "WiFi"/"Vol" labels, ✦ AI button
2. **Dock** (bottom of window) — 4 app icons with hover animations
3. **Dark background** (#0A0E1A)

## What you can interact with

| Action | What happens |
|--------|-------------|
| Click **✦ AI** button in top bar | AI Sidebar slides in from right |
| Click **◆ aurion** text in top bar | Launcher opens |
| Press **Super+Space** | Launcher opens (type to search, Escape to close) |
| Press **Super+A** | AI Sidebar opens |
| Press **Super+Return** | Terminal (foot) opens |
| Type in AI Sidebar | Get mock AI responses (hardware status, errors, system info) |
| Type in Launcher | Search apps, press Enter to select |
| Hover dock icons | Scale animation + tooltip |
| Press **Alt+F4** | Close focused window |
| Close the labwc window | End demo |

## What is working vs mocked

| Component | Status |
|-----------|--------|
| Top Bar (clock, layout) | ✅ Real |
| Dock (icons, animations) | ✅ Real |
| Launcher (search, keyboard nav) | ✅ Real |
| AI Sidebar (chat UI) | ✅ Real UI, mock AI responses |
| Keyboard shortcuts | ✅ Real (via labwc + D-Bus) |
| AI responses | ⚠️ Mocked — canned answers, no real LLM |
| Hardware scanner | ✅ Real scan of VM hardware |
| Diagnostics CLI | ✅ Real (logs work, snapshots need Btrfs) |
| Btrfs snapshots | ⚠️ Only works if you installed Ubuntu on Btrfs |
| Layer-shell surfaces | ⚠️ May show as floating windows if layer-shell-qt missing |
| Plymouth boot theme | ❌ Not active (needs ISO build) |
| Login screen | ❌ Not active (needs greetd setup) |
| Custom GTK/Qt theme | ❌ Not applied yet — using system dark theme |

## Testing hardware scanner separately

```
./hardware-compat/target/release/aurion-hwcompat --scan
./hardware-compat/target/release/aurion-hwcompat --scan --json
```

## Testing diagnostics separately

```
# Collect system logs:
sudo ./diagnostics/target/release/aurion-diag collect-logs
# Output: /tmp/aurion-logs-YYYYMMDD_HHMMSS/

# View the collected files:
ls /tmp/aurion-logs-*/

# Show help:
./diagnostics/target/release/aurion-diag help
```

## Switching AI from mock to real Ollama

```
# Install Ollama:
curl -fsSL https://ollama.com/install.sh | sh
ollama pull phi3:mini

# Edit config:
nano ~/.config/aurion/ai.toml
# Change: provider = "ollama"

# Restart demo:
./scripts/demo-run.sh
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `demo-setup.sh` fails on packages | Run `sudo apt update` first |
| Shell build fails | Check output for missing Qt6 packages |
| labwc window is blank | Check if swaybg and aurion-shell started (look at terminal output) |
| No keyboard shortcuts work | Make sure `~/.config/labwc/rc.xml` exists |
| AI sidebar shows "service not running" | The AI service may have crashed — check terminal output |
