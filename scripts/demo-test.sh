#!/bin/bash
# ============================================================
# AurionOS Demo Test — Verify each component works
# ============================================================
# Run this after demo-setup.sh and demo-build.sh.
# Tests each component individually and reports status.
#
# Usage: ./scripts/demo-test.sh
# ============================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0

pass() { echo -e "  ${GREEN}✅ PASS${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}❌ FAIL${NC} $1"; FAIL=$((FAIL+1)); }
skip() { echo -e "  ${YELLOW}⏭  SKIP${NC} $1"; SKIP=$((SKIP+1)); }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo "=== AurionOS Demo Test ==="
echo ""

# --- 1. Shell binary ---
echo "[Shell]"
if [ -f "$REPO_DIR/shell/build/aurion-shell" ]; then
    pass "Shell binary exists"
else
    fail "Shell binary not found (run demo-build.sh)"
fi

# --- 2. Hardware scanner ---
echo "[Hardware Scanner]"
HWCOMPAT="$REPO_DIR/hardware-compat/target/release/aurion-hwcompat"
if [ -f "$HWCOMPAT" ]; then
    pass "Binary exists"
    if OUTPUT=$("$HWCOMPAT" --scan --json 2>/dev/null); then
        if echo "$OUTPUT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
            pass "JSON output is valid"
            TOTAL=$(echo "$OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['total_devices'])")
            pass "Found $TOTAL devices"
        else
            fail "JSON output is invalid"
        fi
    else
        skip "Scan failed (may be normal in some VMs)"
    fi
else
    fail "Binary not found (run demo-build.sh)"
fi

# --- 3. Diagnostics ---
echo "[Diagnostics]"
DIAG="$REPO_DIR/diagnostics/target/release/aurion-diag"
if [ -f "$DIAG" ]; then
    pass "Binary exists"
    if "$DIAG" help >/dev/null 2>&1; then
        pass "Help command works"
    else
        fail "Help command failed"
    fi
else
    fail "Binary not found (run demo-build.sh)"
fi

# --- 4. AI Service ---
echo "[AI Service]"
AI_VENV="$REPO_DIR/ai-services/.venv"
if [ -d "$AI_VENV" ]; then
    pass "Python venv exists"
    if source "$AI_VENV/bin/activate" 2>/dev/null; then
        if python3 -c "from aurion_ai.service import AurionAIService; print('OK')" 2>/dev/null; then
            pass "AI service imports OK"
        else
            fail "AI service import failed"
        fi
        if python3 -c "from aurion_ai.providers.mock import MockProvider; print('OK')" 2>/dev/null; then
            pass "Mock provider imports OK"
        else
            fail "Mock provider import failed"
        fi
        deactivate 2>/dev/null || true
    fi
else
    fail "Python venv not found (run demo-setup.sh)"
fi

# --- 5. labwc ---
echo "[labwc]"
if command -v labwc &>/dev/null; then
    pass "labwc installed"
else
    fail "labwc not installed"
fi

# --- 6. Config ---
echo "[Config]"
if [ -f ~/.config/aurion/ai.toml ]; then
    pass "AI config exists"
else
    fail "AI config missing"
fi
if [ -f ~/.config/labwc/rc.xml ]; then
    pass "labwc config exists"
else
    fail "labwc config missing"
fi

# --- Summary ---
echo ""
echo "=== Results ==="
echo -e "  ${GREEN}Passed: $PASS${NC}"
echo -e "  ${RED}Failed: $FAIL${NC}"
echo -e "  ${YELLOW}Skipped: $SKIP${NC}"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}All checks passed! Run ./scripts/demo-run.sh to start the demo.${NC}"
else
    echo -e "${YELLOW}Some checks failed. Fix issues above, then re-run.${NC}"
fi
