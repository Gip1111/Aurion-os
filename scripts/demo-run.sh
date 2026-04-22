#!/bin/bash
# ============================================================
# AurionOS Demo Run — Starts the full demo session
# ============================================================
# Starts: AI service → labwc (nested) → Aurion Shell
#
# Usage: ./scripts/demo-run.sh
#
# This runs labwc NESTED inside your current desktop session.
# You will see a window appear containing the AurionOS desktop.
#
# Controls:
#   Super+Space  = Toggle Launcher
#   Super+A      = Toggle AI Sidebar
#   Super+Return = Open terminal
#   Alt+F4       = Close window
#   Close the labwc window = end demo
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[DEMO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SHELL_BIN="$REPO_DIR/shell/build/aurion-shell"
HWCOMPAT_BIN="$REPO_DIR/hardware-compat/target/release/aurion-hwcompat"
DIAG_BIN="$REPO_DIR/diagnostics/target/release/aurion-diag"
AI_VENV="$REPO_DIR/ai-services/.venv"

# --- Check binaries exist ---
[ -f "$SHELL_BIN" ]   || { echo "Shell not built. Run ./scripts/demo-build.sh first."; exit 1; }
[ -d "$AI_VENV" ]     || { echo "AI venv not found. Run ./scripts/demo-setup.sh first."; exit 1; }

# --- Cleanup function ---
cleanup() {
    log "Shutting down demo..."
    [ -n "${AI_PID:-}" ] && kill "$AI_PID" 2>/dev/null || true
    [ -n "${HW_PID:-}" ] && kill "$HW_PID" 2>/dev/null || true
    wait 2>/dev/null
    log "Demo stopped."
}
trap cleanup EXIT

echo ""
log "╔══════════════════════════════════════════╗"
log "║       AurionOS Demo — Starting...        ║"
log "╚══════════════════════════════════════════╝"
echo ""

# --- 1. Start AI service (mock mode, background) ---
log "[1/4] Starting AI service (mock mode)..."
source "$AI_VENV/bin/activate"
python3 -m aurion_ai.service &
AI_PID=$!
deactivate 2>/dev/null || true
sleep 1

if kill -0 "$AI_PID" 2>/dev/null; then
    log "AI service running (PID $AI_PID) ✓"
else
    warn "AI service failed to start (will work without it)"
    AI_PID=""
fi

# --- 2. Run hardware scan ---
if [ -f "$HWCOMPAT_BIN" ]; then
    log "[2/4] Running hardware scan..."
    "$HWCOMPAT_BIN" --scan 2>/dev/null || warn "Hardware scan had issues (expected in some VMs)"
    echo ""
else
    warn "[2/4] Hardware scanner not built, skipping"
fi

# --- 3. Write a temporary labwc autostart for demo ---
log "[3/4] Configuring demo session..."
DEMO_AUTOSTART=$(mktemp)
cat > "$DEMO_AUTOSTART" << EOF
# AurionOS Demo autostart
swaybg -c '#0A0E1A' &
$SHELL_BIN &
EOF

# --- 4. Launch labwc nested ---
log "[4/4] Launching AurionOS desktop..."
echo ""
info "╔══════════════════════════════════════════╗"
info "║  AurionOS Desktop is starting in a new   ║"
info "║  window. Look for the labwc window.       ║"
info "║                                          ║"
info "║  Shortcuts:                              ║"
info "║    Super+Space  → Launcher               ║"
info "║    Super+A      → AI Sidebar             ║"
info "║    Super+Return → Terminal               ║"
info "║                                          ║"
info "║  Close the labwc window to end demo.     ║"
info "╚══════════════════════════════════════════╝"
echo ""

# Use the demo autostart
export XDG_CONFIG_HOME=$(mktemp -d)
mkdir -p "$XDG_CONFIG_HOME/labwc"
cp ~/.config/labwc/rc.xml "$XDG_CONFIG_HOME/labwc/rc.xml" 2>/dev/null || true
cp ~/.config/labwc/environment "$XDG_CONFIG_HOME/labwc/environment" 2>/dev/null || true
cp "$DEMO_AUTOSTART" "$XDG_CONFIG_HOME/labwc/autostart"

# Run labwc nested — this blocks until the window is closed
labwc

log "Demo ended."
