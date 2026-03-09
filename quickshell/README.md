# Quickshell Widget

Claude Code usage widget for [Quickshell](https://github.com/quickshell-mirror/quickshell), designed for [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (the `ii` config).

## Files

| File | Destination | Description |
|---|---|---|
| `services/ClaudeUsage.qml` | `~/.config/quickshell/ii/services/` | Singleton service — fetches API data every 5 min |
| `bar/ClaudeBar.qml` | `~/.config/quickshell/ii/modules/ii/bar/` | Bar indicator (icon + percentage) |
| `bar/ClaudeUsagePopup.qml` | `~/.config/quickshell/ii/modules/ii/bar/` | Hover popup with detailed meters |
| `bar/ClaudeUsageMeter.qml` | `~/.config/quickshell/ii/modules/ii/bar/` | Reusable progress meter component |

## Manual install

1. Copy the files to the destinations listed above.

2. Edit `~/.config/quickshell/ii/modules/ii/bar/BarContent.qml` and add this inside the bar layout (e.g., after `Resources`):

```qml
ClaudeBar {
    Layout.alignment: Qt.AlignVCenter
}
```

3. Restart Quickshell:

```bash
killall qs; qs -c ii
```

## Usage

- **Hover** over the widget to see the detailed popup
- **Right-click** the bar icon to force refresh
- **Click the refresh button** (↻) inside the popup for on-demand refresh

The widget auto-refreshes every 5 minutes by default. To change the interval, edit `fetchInterval` in `ClaudeUsage.qml` (value in milliseconds). The icon dims briefly during API calls and turns red on errors.

## Theming

The widget uses your Quickshell `Appearance` theme colors (Material 3) — it adapts to your color scheme automatically.

Status thresholds:
- `m3primary` for normal (<50%)
- `m3tertiary` for warning (50–79%)
- `m3error` for critical (80%+)
