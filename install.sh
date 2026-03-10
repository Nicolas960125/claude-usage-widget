#!/usr/bin/env bash
set -euo pipefail

# Claude Code Usage Widget — Installer
# Installs the Quickshell widget for end-4/dots-hyprland.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()  { echo -e "${CYAN}::${RESET} $1"; }
ok()    { echo -e "${GREEN}✓${RESET} $1"; }
warn()  { echo -e "${YELLOW}!${RESET} $1"; }
err()   { echo -e "${RED}✗${RESET} $1"; }

# ── Preflight checks ────────────────────────────────────────────────

echo -e "\n${BOLD}Claude Code Usage Widget${RESET} — Installer\n"

# Check credentials
if [[ ! -f "$HOME/.claude/.credentials.json" ]]; then
    err "~/.claude/.credentials.json not found."
    echo "   Make sure Claude Code is installed and you're logged in."
    echo "   Run 'claude' first, then re-run this installer."
    exit 1
fi
ok "Claude Code credentials found"

# ── Detect Quickshell ────────────────────────────────────────────────

QS_CONFIG_DIR="$HOME/.config/quickshell/ii"
if [[ ! -d "$QS_CONFIG_DIR/modules/ii/bar" || ! -d "$QS_CONFIG_DIR/services" ]]; then
    err "Quickshell (end-4/dots-hyprland) not found."
    echo "   Expected config at: $QS_CONFIG_DIR"
    echo "   Install end-4/dots-hyprland first, then re-run this installer."
    exit 1
fi
ok "Quickshell (end-4/dots-hyprland) detected"

echo ""

# ── Install ──────────────────────────────────────────────────────────

info "Installing Quickshell widget..."

# Service
cp "$REPO_DIR/quickshell/services/ClaudeUsage.qml" \
   "$QS_CONFIG_DIR/services/ClaudeUsage.qml"
ok "Installed services/ClaudeUsage.qml"

# Bar components
BAR_DIR="$QS_CONFIG_DIR/modules/ii/bar"
cp "$REPO_DIR/quickshell/bar/ClaudeBar.qml" "$BAR_DIR/ClaudeBar.qml"
cp "$REPO_DIR/quickshell/bar/ClaudeUsagePopup.qml" "$BAR_DIR/ClaudeUsagePopup.qml"
cp "$REPO_DIR/quickshell/bar/ClaudeUsageMeter.qml" "$BAR_DIR/ClaudeUsageMeter.qml"
ok "Installed bar components (ClaudeBar, ClaudeUsagePopup, ClaudeUsageMeter)"

# Patch BarContent.qml to include ClaudeBar
BARCONTENT="$BAR_DIR/BarContent.qml"
if [[ -f "$BARCONTENT" ]]; then
    if grep -q "ClaudeBar" "$BARCONTENT"; then
        ok "BarContent.qml already contains ClaudeBar"
    else
        # Insert ClaudeBar before the Media block
        PATCH_MARKER="Media {"
        if grep -q "$PATCH_MARKER" "$BARCONTENT"; then
            sed -i "/$PATCH_MARKER/i\\
\\
            ClaudeBar {\\
                Layout.alignment: Qt.AlignVCenter\\
            }" "$BARCONTENT"
            ok "Patched BarContent.qml — added ClaudeBar before Media"
        else
            warn "Could not auto-patch BarContent.qml"
            echo "   Add this manually inside your bar layout:"
            echo ""
            echo "       ClaudeBar {"
            echo "           Layout.alignment: Qt.AlignVCenter"
            echo "       }"
            echo ""
        fi
    fi
else
    warn "BarContent.qml not found at expected path"
    echo "   You'll need to add ClaudeBar to your bar layout manually."
fi

echo ""
ok "Installation complete"
echo -e "   ${DIM}Restart Quickshell: killall qs; qs -c ii${RESET}"
echo ""
echo -e "${GREEN}${BOLD}Done!${RESET}"
