# Claude Code Usage Widget

Desktop widgets that show your **Claude Code** usage limits in real time — session (5h window), weekly, and per-model (Sonnet) utilization with reset countdowns.

Works with **[Quickshell](https://github.com/quickshell-mirror/quickshell)** (for [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)) and **[Waybar](https://github.com/Alexays/Waybar)**.

<!-- ![Screenshot](screenshots/preview.png) -->

## How it works

Claude Code stores an OAuth token in `~/.claude/.credentials.json` when you log in. This widget reads that token and queries the same internal API that Claude Code uses (`GET /api/oauth/usage`) to fetch your current utilization and reset times.

**No Anthropic API key needed** — it piggybacks on your existing Claude Code session.

---

## Prerequisites

Before installing the widget, make sure you have:

### 1. Claude Code (required)

You need [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) installed and logged in with an active **Max** or **Pro** subscription.

```bash
# Install Claude Code (if you haven't already)
npm install -g @anthropic-ai/claude-code

# Log in — this creates the credentials file the widget needs
claude
```

### 2. Verify your credentials exist

After logging in, check that the credentials file was created:

```bash
cat ~/.claude/.credentials.json | python3 -m json.tool | head -5
```

You should see something like:

```json
{
    "claudeAiOauth": {
        "accessToken": "eyJhb...",
        ...
    }
}
```

> **If the file doesn't exist:** run `claude` and complete the login flow. The widget cannot work without this file.

### 3. Python 3.6+

The API fetch script uses Python's standard library only (no pip packages).

```bash
python3 --version  # Should be 3.6+
```

### 4. A supported bar

One of:
- **Quickshell** with [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (`ii` config)
- **Waybar** (any setup — standalone or embedded)

---

## Install

```bash
git clone https://github.com/Nicolas960125/claude-usage-widget.git
cd claude-usage-widget
./install.sh
```

The interactive installer will:

1. **Validate** that `~/.claude/.credentials.json` exists
2. **Detect** whether you have Quickshell, Waybar, or both
3. **Ask** which variant(s) to install
4. **Copy** files to the correct config directories
5. **Patch** your bar config (or show manual instructions if it can't auto-patch)

### Quick test after installing

**Waybar:**
```bash
# Test the script directly (should print JSON)
python3 ~/.config/waybar/scripts/claude-usage.py

# Launch the standalone bar
waybar -c ~/.config/waybar/config-claude.jsonc -s ~/.config/waybar/style-claude.css
```

**Quickshell:**
```bash
# Restart Quickshell to load the new widget
killall qs; qs -c ii
```

### Manual install

If you prefer not to use the installer, see the variant-specific guides:
- [quickshell/README.md](quickshell/README.md) — file locations, BarContent.qml patch, theming
- [waybar/README.md](waybar/README.md) — standalone vs embedded, Hyprland autostart

---

## What you see

| Metric | Description |
|---|---|
| **Session (5h)** | Rolling 5-hour usage window |
| **Week (all)** | 7-day usage across all models |
| **Week (Sonnet)** | 7-day Sonnet-specific limit (shown only when >0%) |
| **Extra usage** | Pay-as-you-go credits, if enabled |

Each meter shows: **current %**, progress bar, and **time until reset** (relative + absolute).

Color thresholds:
- **Normal** (< 50%) — accent color (Mauve / primary)
- **Warning** (50–79%) — yellow / tertiary
- **Critical** (80%+) — red / error

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `Credentials not found` | Run `claude` and log in, then retry |
| `Authentication failed (401)` | Your OAuth token expired — restart Claude Code (`claude`) to refresh it, then retry |
| Widget shows `--` or `!` | Check the Quickshell logs (`journalctl --user -u quickshell`) or run the Waybar script manually |
| Waybar tooltip doesn't appear | The standalone config uses `passthrough: true` — hover works but clicks pass through. This is by design |

> **Token refresh:** Claude Code's OAuth token can expire. When it does, the widget will show an error. Simply open a new Claude Code session (`claude`) to refresh the token — the widget picks it up automatically on the next poll (every 60s).

---

## Customization

### Waybar

Edit `~/.config/waybar/style-claude.css` — all colors are documented with their Catppuccin Mocha names. Swap the hex values for your preferred theme.

To change the refresh interval, edit `"interval": 60` in the config (value in seconds).

### Quickshell

The widget uses your Quickshell theme's `Appearance` colors automatically — it follows your system theme out of the box.

---

## Uninstall

### Quickshell

```bash
rm ~/.config/quickshell/ii/services/ClaudeUsage.qml
rm ~/.config/quickshell/ii/modules/ii/bar/Claude{Bar,UsagePopup,UsageMeter}.qml
# Then remove the ClaudeBar block from BarContent.qml manually
```

### Waybar

```bash
rm ~/.config/waybar/scripts/claude-usage.py
rm ~/.config/waybar/config-claude.jsonc
rm ~/.config/waybar/style-claude.css
# Then remove the exec-once line from ~/.config/hypr/custom/execs.conf
```

---

## API reference

This widget uses an **undocumented internal API** from Anthropic. It may change without notice.

| | |
|---|---|
| **Endpoint** | `GET https://api.anthropic.com/api/oauth/usage` |
| **Auth** | `Authorization: Bearer <token>` |
| **Required header** | `anthropic-beta: oauth-2025-04-20` |
| **Token source** | `~/.claude/.credentials.json` → `claudeAiOauth.accessToken` |

<details>
<summary>Example API response</summary>

```json
{
  "five_hour": {
    "utilization": 14.0,
    "resets_at": "2025-02-25T05:59:59.935947+00:00"
  },
  "seven_day": {
    "utilization": 15.0,
    "resets_at": "2025-03-03T12:59:59.935969+00:00"
  },
  "seven_day_sonnet": {
    "utilization": 1.0,
    "resets_at": "2025-02-25T23:00:00.935977+00:00"
  },
  "extra_usage": {
    "is_enabled": false,
    "monthly_limit": null,
    "used_credits": null,
    "utilization": null
  }
}
```

</details>

## License

MIT
