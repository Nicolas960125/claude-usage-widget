#!/usr/bin/env bash
set -euo pipefail

# Claude Code Usage Widget — Installer
# Detects Quickshell and/or Waybar and installs the appropriate widget.

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

# ── Detect available targets ─────────────────────────────────────────

HAS_QUICKSHELL=false
HAS_WAYBAR=false

# Quickshell: look for end-4/dots-hyprland ii config
QS_CONFIG_DIR="$HOME/.config/quickshell/ii"
if [[ -d "$QS_CONFIG_DIR/modules/ii/bar" && -d "$QS_CONFIG_DIR/services" ]]; then
    HAS_QUICKSHELL=true
fi

if command -v waybar &>/dev/null; then
    HAS_WAYBAR=true
fi

if ! $HAS_QUICKSHELL && ! $HAS_WAYBAR; then
    err "Neither Quickshell (end-4/dots-hyprland) nor Waybar found."
    echo "   Install one of them first, then re-run this installer."
    exit 1
fi

echo ""
info "Detected:"
$HAS_QUICKSHELL && echo "   • Quickshell (end-4/dots-hyprland)"
$HAS_WAYBAR && echo "   • Waybar"
echo ""

# ── Target selection ─────────────────────────────────────────────────

INSTALL_QS=false
INSTALL_WB=false

if $HAS_QUICKSHELL && $HAS_WAYBAR; then
    echo "What would you like to install?"
    echo "  1) Quickshell widget only"
    echo "  2) Waybar widget only"
    echo "  3) Both"
    echo ""
    read -rp "Choice [1/2/3]: " choice
    case "$choice" in
        1) INSTALL_QS=true ;;
        2) INSTALL_WB=true ;;
        3) INSTALL_QS=true; INSTALL_WB=true ;;
        *) err "Invalid choice"; exit 1 ;;
    esac
elif $HAS_QUICKSHELL; then
    INSTALL_QS=true
else
    INSTALL_WB=true
fi

echo ""

# ── Install Quickshell ───────────────────────────────────────────────

if $INSTALL_QS; then
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
            # Insert ClaudeBar after the Resources block
            if grep -q "Resources {" "$BARCONTENT"; then
                # Find the closing brace of Resources and insert after it
                # Use a simple approach: insert after the line containing "Resources {"
                # and its closing block
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
            else
                warn "Could not find Resources block in BarContent.qml"
                echo "   Add ClaudeBar manually to your bar layout."
            fi
        fi
    else
        warn "BarContent.qml not found at expected path"
        echo "   You'll need to add ClaudeBar to your bar layout manually."
    fi

    echo ""
    ok "Quickshell installation complete"
    echo -e "   ${DIM}Restart Quickshell: killall qs; qs -c ii${RESET}"
    echo ""
fi

# ── Install Waybar ───────────────────────────────────────────────────

if $INSTALL_WB; then
    info "Installing Waybar widget..."

    WAYBAR_DIR="$HOME/.config/waybar"
    mkdir -p "$WAYBAR_DIR/scripts"

    cp "$REPO_DIR/waybar/scripts/claude-usage.py" "$WAYBAR_DIR/scripts/claude-usage.py"
    chmod +x "$WAYBAR_DIR/scripts/claude-usage.py"
    ok "Installed scripts/claude-usage.py"

    cp "$REPO_DIR/waybar/config-claude.jsonc" "$WAYBAR_DIR/config-claude.jsonc"
    ok "Installed config-claude.jsonc"

    cp "$REPO_DIR/waybar/style-claude.css" "$WAYBAR_DIR/style-claude.css"
    ok "Installed style-claude.css"

    # Add exec-once to Hyprland config
    HYPR_EXECS="$HOME/.config/hypr/custom/execs.conf"
    EXEC_LINE='exec-once = waybar -c ~/.config/waybar/config-claude.jsonc -s ~/.config/waybar/style-claude.css'

    if [[ -f "$HYPR_EXECS" ]]; then
        if grep -q "config-claude.jsonc" "$HYPR_EXECS"; then
            ok "Hyprland exec-once already configured"
        else
            echo "" >> "$HYPR_EXECS"
            echo "# Claude Code usage widget" >> "$HYPR_EXECS"
            echo "$EXEC_LINE" >> "$HYPR_EXECS"
            ok "Added exec-once to $HYPR_EXECS"
        fi
    elif [[ -d "$HOME/.config/hypr" ]]; then
        warn "No custom/execs.conf found"
        echo "   Add this to your Hyprland config:"
        echo ""
        echo "   $EXEC_LINE"
        echo ""
    else
        info "Not using Hyprland? Start the widget manually:"
        echo "   $EXEC_LINE"
        echo ""
    fi

    echo ""
    ok "Waybar installation complete"
    echo -e "   ${DIM}Test it: python3 ~/.config/waybar/scripts/claude-usage.py${RESET}"
    echo -e "   ${DIM}Launch: waybar -c ~/.config/waybar/config-claude.jsonc -s ~/.config/waybar/style-claude.css${RESET}"
    echo ""
fi

# ── Done ─────────────────────────────────────────────────────────────

echo -e "${GREEN}${BOLD}Done!${RESET}"
