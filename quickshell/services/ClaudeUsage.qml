pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.common

Singleton {
    id: root

    // Refresh interval in milliseconds. Increase to avoid rate-limiting (429).
    // Default: 300000 (5 min). Minimum recommended: 60000 (1 min).
    property int fetchInterval: 300000

    property real sessionPct: 0
    property string sessionReset: ""
    property string sessionResetAbs: ""

    property real weekPct: 0
    property string weekReset: ""
    property string weekResetAbs: ""

    property real sonnetPct: 0
    property string sonnetReset: ""
    property string sonnetResetAbs: ""

    property bool hasData: false
    property bool loading: false
    property bool error: false
    property string errorMessage: ""
    property string lastRefresh: ""

    // Rate-limit guard: minimum 60s between requests
    property real _lastFetchTime: 0
    readonly property int _minInterval: 60000

    function refresh() {
        const now = Date.now();
        const elapsed = now - _lastFetchTime;
        if (elapsed < _minInterval) {
            console.warn(`[ClaudeUsage] Throttled: ${Math.ceil((_minInterval - elapsed) / 1000)}s until next allowed request`);
            return;
        }
        _lastFetchTime = now;
        fetcher.running = true;
    }

    function parseData(jsonStr) {
        try {
            const data = JSON.parse(jsonStr);

            const five = data.five_hour || {};
            const week = data.seven_day || {};
            const sonnet = data.seven_day_sonnet || {};

            root.sessionPct = (five.utilization || 0) / 100;
            root.weekPct = (week.utilization || 0) / 100;
            root.sonnetPct = (sonnet.utilization || 0) / 100;

            root.sessionReset = formatTimeUntil(five.resets_at);
            root.sessionResetAbs = formatAbsoluteTime(five.resets_at);

            root.weekReset = formatTimeUntil(week.resets_at);
            root.weekResetAbs = formatAbsoluteTime(week.resets_at);

            root.sonnetReset = formatTimeUntil(sonnet.resets_at);
            root.sonnetResetAbs = formatAbsoluteTime(sonnet.resets_at);

            root.hasData = true;
            root.error = false;
            root.errorMessage = "";

            const now = new Date();
            root.lastRefresh = now.getHours().toString().padStart(2, '0') + ":" +
                               now.getMinutes().toString().padStart(2, '0');
        } catch (e) {
            root.error = true;
            root.errorMessage = e.message;
            console.error(`[ClaudeUsage] Parse error: ${e.message}`);
        }
    }

    function formatTimeUntil(isoStr) {
        if (!isoStr) return "";
        const target = new Date(isoStr);
        const now = new Date();
        let totalSecs = Math.max(0, Math.floor((target - now) / 1000));

        if (totalSecs < 3600) {
            return `${Math.floor(totalSecs / 60)}min`;
        }
        const hours = Math.floor(totalSecs / 3600);
        const mins = Math.floor((totalSecs % 3600) / 60);
        if (hours < 24) {
            return `${hours}h ${mins}m`;
        }
        const days = Math.floor(hours / 24);
        const remHours = hours % 24;
        return `${days}d ${remHours}h`;
    }

    function formatAbsoluteTime(isoStr) {
        if (!isoStr) return "";
        const target = new Date(isoStr);
        const now = new Date();

        let dayLabel;
        if (target.toDateString() === now.toDateString()) {
            dayLabel = "today";
        } else {
            const tomorrow = new Date(now);
            tomorrow.setDate(tomorrow.getDate() + 1);
            if (target.toDateString() === tomorrow.toDateString()) {
                dayLabel = "tomorrow";
            } else {
                const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                dayLabel = `${days[target.getDay()]} ${target.getDate()}`;
            }
        }

        let hours = target.getHours();
        const mins = target.getMinutes().toString().padStart(2, '0');
        const ampm = hours >= 12 ? "PM" : "AM";
        hours = hours % 12 || 12;
        return `${dayLabel} ${hours}:${mins} ${ampm}`;
    }

    Process {
        id: fetcher
        command: ["python3", "-c", `
import json, os, sys
creds_path = os.path.expanduser("~/.claude/.credentials.json")
if not os.path.exists(creds_path):
    print('{"error": "credentials not found"}')
    sys.exit(0)
try:
    from urllib.request import Request, urlopen
    from urllib.error import HTTPError
    creds = json.load(open(creds_path))
    token = creds["claudeAiOauth"]["accessToken"]
    req = Request("https://api.anthropic.com/api/oauth/usage", headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "User-Agent": "claude-code",
        "anthropic-beta": "oauth-2025-04-20",
    })
    resp = urlopen(req, timeout=10)
    print(resp.read().decode())
except HTTPError as e:
    body = ""
    try: body = e.read().decode()
    except: pass
    print(json.dumps({"error": f"HTTP {e.code}", "status": e.code, "body": body}))
except Exception as e:
    print(json.dumps({"error": str(e)}))
`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    try {
                        const obj = JSON.parse(text);
                        if (obj.error) {
                            root.error = true;
                            root.errorMessage = obj.error;
                            if (obj.status === 429) {
                                console.warn("[ClaudeUsage] 429 rate limited, backing off 2min");
                                root._lastFetchTime = Date.now() + 60000; // block for 2min total
                            }
                            root.loading = false;
                            return;
                        }
                    } catch (e) {
                        // Not a simple error object, try parsing as usage data
                    }
                    root.parseData(text);
                }
                root.loading = false;
            }
        }
        onRunningChanged: {
            if (running) root.loading = true;
        }
    }

    Timer {
        running: true
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
