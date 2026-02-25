#!/usr/bin/env python3
"""Claude Code usage tracker for Waybar — reads from the Anthropic OAuth API."""
import json
import os
import sys
from datetime import datetime, timezone, timedelta
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

CREDENTIALS_PATH = os.path.expanduser("~/.claude/.credentials.json")
API_URL = "https://api.anthropic.com/api/oauth/usage"

LOCAL_TZ = datetime.now(timezone.utc).astimezone().tzinfo


def load_token():
    if not os.path.exists(CREDENTIALS_PATH):
        raise FileNotFoundError(
            f"Credentials not found at {CREDENTIALS_PATH}. "
            "Make sure Claude Code is installed and you're logged in."
        )
    with open(CREDENTIALS_PATH) as f:
        creds = json.load(f)
    try:
        return creds["claudeAiOauth"]["accessToken"]
    except KeyError:
        raise KeyError(
            "No OAuth token found in credentials. "
            "Run 'claude' and log in first."
        )


def fetch_usage(token):
    req = Request(API_URL, headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "User-Agent": "claude-code",
        "anthropic-beta": "oauth-2025-04-20",
    })
    try:
        resp = urlopen(req, timeout=10)
        return json.loads(resp.read())
    except HTTPError as e:
        if e.code == 401:
            raise URLError(
                "Authentication failed (401). Your token may have expired — "
                "restart Claude Code to refresh it."
            )
        raise


def time_until(iso_str):
    """Returns (relative_str, absolute_str)."""
    if not iso_str:
        return "", ""
    dt = datetime.fromisoformat(iso_str).astimezone(LOCAL_TZ)
    now = datetime.now(timezone.utc).astimezone(LOCAL_TZ)
    diff = dt - now
    total_secs = max(0, int(diff.total_seconds()))

    # Relative
    if total_secs < 3600:
        rel = f"{total_secs // 60}min"
    else:
        hours = total_secs // 3600
        mins = (total_secs % 3600) // 60
        if hours < 24:
            rel = f"{hours}h {mins}m"
        else:
            days = hours // 24
            remaining_hours = hours % 24
            rel = f"{days}d {remaining_hours}h"

    # Absolute: "today 1:00 PM" or "Tue 25 8:00 AM"
    if dt.date() == now.date():
        day_label = "today"
    elif dt.date() == (now + timedelta(days=1)).date():
        day_label = "tomorrow"
    else:
        days_en = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        day_label = f"{days_en[dt.weekday()]} {dt.day}"

    hour = dt.strftime("%-I:%M %p")
    absolute = f"{day_label} {hour}"

    return rel, absolute


def make_bar(pct, width=20):
    """Create a text-based progress bar."""
    filled = round(pct / 100 * width)
    empty = width - filled
    return "\u2588" * filled + "\u2591" * empty


def main():
    try:
        token = load_token()
        data = fetch_usage(token)
    except (FileNotFoundError, KeyError, URLError, HTTPError) as e:
        print(json.dumps({
            "text": " --",
            "tooltip": f"Error: {e}",
            "class": "claude error",
        }))
        return

    five = data.get("five_hour") or {}
    week = data.get("seven_day") or {}
    sonnet = data.get("seven_day_sonnet") or {}

    session_pct = five.get("utilization", 0) or 0
    week_pct = week.get("utilization", 0) or 0
    sonnet_pct = sonnet.get("utilization", 0) or 0

    session_rel, session_abs = time_until(five.get("resets_at"))
    week_rel, week_abs = time_until(week.get("resets_at"))
    sonnet_rel, sonnet_abs = time_until(sonnet.get("resets_at"))

    # Bar text
    max_pct = max(session_pct, week_pct)
    text = f" {int(session_pct)}%  {int(week_pct)}%"

    # Tooltip — uses Pango markup; colors are kept here because Waybar tooltips
    # are styled via Pango spans, not CSS (CSS only styles the outer tooltip box).
    t = []
    t.append('<span font_desc="JetBrains Mono 11" foreground="#cba6f7"><b>  Claude Code</b></span>')
    t.append("")

    # Session
    t.append('<span foreground="#a6adc8"><b>Session (5h)</b></span>')
    t.append(f'<span font_desc="JetBrains Mono 9">{make_bar(session_pct)}  <b>{int(session_pct)}%</b></span>')
    if session_rel:
        t.append(f'<span foreground="#6c7086">  Resets in {session_rel}  \u00b7  {session_abs}</span>')
    t.append("")

    # Weekly
    t.append('<span foreground="#a6adc8"><b>Week (all)</b></span>')
    t.append(f'<span font_desc="JetBrains Mono 9">{make_bar(week_pct)}  <b>{int(week_pct)}%</b></span>')
    if week_rel:
        t.append(f'<span foreground="#6c7086">  Resets in {week_rel}  \u00b7  {week_abs}</span>')

    # Sonnet (only if >0)
    if sonnet_pct > 0:
        t.append("")
        t.append('<span foreground="#a6adc8"><b>Week (Sonnet)</b></span>')
        t.append(f'<span font_desc="JetBrains Mono 9">{make_bar(sonnet_pct)}  <b>{int(sonnet_pct)}%</b></span>')
        if sonnet_rel:
            t.append(f'<span foreground="#6c7086">  Resets in {sonnet_rel}  \u00b7  {sonnet_abs}</span>')

    # Extra usage
    extra = data.get("extra_usage", {})
    if extra and extra.get("is_enabled") and extra.get("used_credits") is not None:
        used = extra["used_credits"] / 100
        limit = (extra.get("monthly_limit") or 0) / 100
        util = extra.get("utilization", 0) or 0
        t.append("")
        t.append('<span foreground="#a6adc8"><b>Extra usage</b></span>')
        t.append(f'<span font_desc="JetBrains Mono 9">{make_bar(util)}  <b>${used:.2f} / ${limit:.2f}</b></span>')

    # CSS class
    css_class = "claude"
    if max_pct >= 80:
        css_class = "claude critical"
    elif max_pct >= 50:
        css_class = "claude warning"

    output = {
        "text": text,
        "tooltip": "\n".join(t),
        "class": css_class,
        "percentage": int(max_pct),
    }
    print(json.dumps(output))


if __name__ == "__main__":
    main()
