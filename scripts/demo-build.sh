#!/bin/bash
# ============================================================
# AurionOS Demo Build — Builds all components
# ============================================================
# Run this after demo-setup.sh. Re-run any time you change code.
#
# Usage: ./scripts/demo-build.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[BUILD]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

# Source Rust env if needed
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

log "=== AurionOS Demo Build ==="
echo ""

# --- 1. Build the shell ---
log "[1/3] Building Aurion Shell (Qt6/QML)..."
cd "$REPO_DIR/shell"
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release 2>&1 | grep -E "(layer-shell|WARNING|Error|--)" || true
make -j"$(nproc)" 2>&1

if [ -f aurion-shell ]; then
    log "Shell built successfully ✓"
    log "Binary: $REPO_DIR/shell/build/aurion-shell"
else
    fail "Shell build failed. Check Qt6 dev packages."
fi

# --- 2. Build hardware scanner ---
log "[2/3] Building Hardware Scanner (Rust)..."
cd "$REPO_DIR/hardware-compat"
cargo build --release 2>&1 | tail -3

if [ -f target/release/aurion-hwcompat ]; then
    log "Hardware scanner built ✓"
else
    fail "Hardware scanner build failed."
fi

# --- 3. Build diagnostics ---
log "[3/3] Building Diagnostics (Rust)..."
cd "$REPO_DIR/diagnostics"
cargo build --release 2>&1 | tail -3

if [ -f target/release/aurion-diag ]; then
    log "Diagnostics built ✓"
else
    fail "Diagnostics build failed."
fi

echo ""
log "=== Build Complete ==="
log "All binaries ready. Next: run ./scripts/demo-run.sh"
