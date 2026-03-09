# Waybar Widget

Claude Code usage widget for [Waybar](https://github.com/Alexays/Waybar).

Runs as a standalone bottom bar (passthrough, non-exclusive) with a single centered module showing your Claude Code usage.

## Files

| File | Destination | Description |
|---|---|---|
| `scripts/claude-usage.py` | `~/.config/waybar/scripts/` | Python script — fetches API, outputs Waybar JSON |
| `config-claude.jsonc` | `~/.config/waybar/` | Waybar config (standalone bar) |
| `style-claude.css` | `~/.config/waybar/` | Catppuccin Mocha styling |

## Manual install

1. Copy the files to the destinations listed above.
2. Make the script executable: `chmod +x ~/.config/waybar/scripts/claude-usage.py`
3. Test it:

```bash
python3 ~/.config/waybar/scripts/claude-usage.py
```

4. Launch the bar:

```bash
waybar -c ~/.config/waybar/config-claude.jsonc -s ~/.config/waybar/style-claude.css
```

5. To auto-start with Hyprland, add to `~/.config/hypr/custom/execs.conf`:

```ini
exec-once = waybar -c ~/.config/waybar/config-claude.jsonc -s ~/.config/waybar/style-claude.css
```

## Embedding in your existing bar

Instead of running a separate Waybar instance, you can add the module to your existing config:

1. Add to your Waybar config's modules list: `"custom/claude"`
2. Add the `"custom/claude"` block from `config-claude.jsonc`
3. Add the styles from `style-claude.css` to your stylesheet

## Usage

- **Click** the widget to force an immediate refresh
- The widget auto-refreshes every 5 minutes by default

To change the interval, edit `"interval"` in `config-claude.jsonc` (value in seconds).

## Theming

The default theme is **Catppuccin Mocha**. All colors in `style-claude.css` are commented with their Catppuccin names — swap the values to match your theme.

The tooltip uses Pango markup with inline colors (Waybar tooltip text can't be styled via CSS). To change tooltip colors, edit the `<span foreground="...">` values in `claude-usage.py`.

## Bar text format

The bar shows: ` {session}%  {week}%`

Where `` = timer icon and `` = calendar icon (Nerd Font).
