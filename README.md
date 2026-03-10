# Claude Code Usage Widget

Desktop widget that shows your **Claude Code** usage limits in real time — session (5h window), weekly, and per-model (Sonnet) utilization with reset countdowns.

Works with **[Quickshell](https://github.com/quickshell-mirror/quickshell)** (for [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)).

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

### 3. Quickshell with end-4/dots-hyprland

You need [Quickshell](https://github.com/quickshell-mirror/quickshell) with the [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) `ii` config.

---

## Install

```bash
git clone https://github.com/Nicolas960125/claude-usage-widget.git
cd claude-usage-widget
./install.sh
```

The installer will:

1. **Validate** that `~/.claude/.credentials.json` exists
2. **Verify** that Quickshell (end-4/dots-hyprland) is installed
3. **Copy** files to the correct config directories
4. **Patch** your bar config (or show manual instructions if it can't auto-patch)

### Quick test after installing

```bash
# Restart Quickshell to load the new widget
killall qs; qs -c ii
```

### Manual install

See [quickshell/README.md](quickshell/README.md) for file locations, BarContent.qml patch, and theming details.

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
| Widget shows `--` or `!` | Check the Quickshell logs (`journalctl --user -u quickshell`) |

> **Token refresh:** Claude Code's OAuth token can expire. When it does, the widget will show an error. Simply open a new Claude Code session (`claude`) to refresh the token — the widget picks it up automatically on the next poll.
>
> **Rate limiting (429):** The default refresh interval is 5 minutes to avoid hitting the API rate limit. You can lower it, but going below 1 minute is not recommended.

---

## Customization

The widget uses your Quickshell theme's `Appearance` colors automatically — it follows your system theme out of the box.

To change the refresh interval, edit `fetchInterval` in `ClaudeUsage.qml` (value in milliseconds, default: 300000 = 5 min). Right-click the bar icon or use the refresh button in the popup for on-demand refresh.

---

## Uninstall

```bash
rm ~/.config/quickshell/ii/services/ClaudeUsage.qml
rm ~/.config/quickshell/ii/modules/ii/bar/Claude{Bar,UsagePopup,UsageMeter}.qml
# Then remove the ClaudeBar block from BarContent.qml manually
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
