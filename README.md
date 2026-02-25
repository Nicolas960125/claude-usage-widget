# Claude Code Usage Widget

Desktop widgets that show your **Claude Code** usage limits in real time — session (5h window), weekly, and per-model (Sonnet) utilization with reset countdowns.

Works with **[Quickshell](https://github.com/quickshell-mirror/quickshell)** (for [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)) and **[Waybar](https://github.com/Alexays/Waybar)**.

<!-- ![Screenshot](screenshots/preview.png) -->

## How it works

Claude Code stores an OAuth token in `~/.claude/.credentials.json`. This widget reads that token and calls `GET https://api.anthropic.com/api/oauth/usage` (the same endpoint Claude Code uses internally) to fetch your current utilization percentages and reset times.

**No API key needed** — it uses the existing OAuth session from your Claude Code login.

## Requirements

- **Claude Code** installed and logged in (active Max/Pro subscription)
- **Python 3.6+** (for the API fetch script)
- One of:
  - **Quickshell** with [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) config
  - **Waybar** (any setup)

## Install

```bash
git clone https://github.com/your-user/claude-usage-widget.git
cd claude-usage-widget
chmod +x install.sh
./install.sh
```

The installer will:
1. Check that `~/.claude/.credentials.json` exists
2. Detect whether you have Quickshell, Waybar, or both
3. Copy the files to the right locations
4. Patch your bar config (or show manual instructions)

See [quickshell/README.md](quickshell/README.md) or [waybar/README.md](waybar/README.md) for variant-specific details.

## What you get

| Metric | Description |
|---|---|
| **Session (5h)** | Rolling 5-hour usage window |
| **Week (all)** | 7-day usage across all models |
| **Week (Sonnet)** | 7-day Sonnet-specific limit (shown only when >0%) |
| **Extra usage** | Pay-as-you-go credits, if enabled |

Each meter shows: current %, progress bar, time until reset (relative + absolute).

Color thresholds:
- **Normal** (< 50%) — accent color (Mauve/primary)
- **Warning** (50–79%) — yellow/tertiary
- **Critical** (80%+) — red/error

## Customization

### Waybar

Edit `~/.config/waybar/style-claude.css` — all colors are documented with their Catppuccin Mocha names. Swap the hex values for your preferred theme.

To change the refresh interval, edit `"interval": 60` in the config (value in seconds).

### Quickshell

The widget uses your Quickshell theme's `Appearance` colors automatically. No color customization needed — it follows your system theme.

## Uninstall

### Quickshell

```bash
rm ~/.config/quickshell/ii/services/ClaudeUsage.qml
rm ~/.config/quickshell/ii/modules/ii/bar/Claude{Bar,UsagePopup,UsageMeter}.qml
# Remove the ClaudeBar block from BarContent.qml manually
```

### Waybar

```bash
rm ~/.config/waybar/scripts/claude-usage.py
rm ~/.config/waybar/config-claude.jsonc
rm ~/.config/waybar/style-claude.css
# Remove the exec-once line from ~/.config/hypr/custom/execs.conf
```

## API details

| | |
|---|---|
| **Endpoint** | `GET https://api.anthropic.com/api/oauth/usage` |
| **Auth** | `Bearer <accessToken>` from `~/.claude/.credentials.json` |
| **Required header** | `anthropic-beta: oauth-2025-04-20` |
| **Token source** | `claudeAiOauth.accessToken` in the credentials file |

This is an undocumented internal API used by Claude Code. It may change without notice.

## License

MIT
