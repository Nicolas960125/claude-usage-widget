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
        if (elapsed < _minInterval && hasData) {
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
        command: ["/usr/bin/python3", "-c", `
import json, os, sys, time
from urllib.request import Request, urlopen
from urllib.error import HTTPError

CREDS_PATH = os.path.expanduser("~/.claude/.credentials.json")
CLIENT_ID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
TOKEN_URL = "https://console.anthropic.com/v1/oauth/token"
UA = "claude-code/2.1.72"

def load_creds():
    if not os.path.exists(CREDS_PATH):
        return None
    return json.load(open(CREDS_PATH))

def save_creds(creds):
    with open(CREDS_PATH, "w") as f:
        json.dump(creds, f, indent=2)

def refresh_token(creds):
    oauth = creds["claudeAiOauth"]
    body = json.dumps({
        "grant_type": "refresh_token",
        "refresh_token": oauth["refreshToken"],
        "client_id": CLIENT_ID,
    }).encode()
    req = Request(TOKEN_URL, data=body, headers={"Content-Type": "application/json", "User-Agent": UA}, method="POST")
    resp = urlopen(req, timeout=10)
    data = json.loads(resp.read().decode())
    oauth["accessToken"] = data["access_token"]
    oauth["refreshToken"] = data["refresh_token"]
    oauth["expiresAt"] = int(time.time() * 1000) + data.get("expires_in", 28800) * 1000
    save_creds(creds)
    return oauth["accessToken"]

def fetch_usage(token):
    req = Request(USAGE_URL, headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "User-Agent": UA,
        "anthropic-beta": "oauth-2025-04-20",
    })
    return urlopen(req, timeout=10).read().decode()

creds = load_creds()
if not creds:
    print('{"error": "credentials not found"}')
    sys.exit(0)

try:
    oauth = creds["claudeAiOauth"]
    token = oauth["accessToken"]
    # Proactively refresh if token expires within 5 minutes
    expires_at = oauth.get("expiresAt", 0)
    if time.time() * 1000 > expires_at - 300000:
        try:
            token = refresh_token(creds)
        except Exception:
            pass  # Try with existing token anyway
    try:
        print(fetch_usage(token))
    except HTTPError as e:
        if e.code in (401, 403):
            # Token rejected — re-read creds in case claude-code refreshed them
            creds = load_creds()
            oauth = creds["claudeAiOauth"]
            fresh_token = oauth["accessToken"]
            if fresh_token != token:
                # claude-code updated the token, use the new one
                print(fetch_usage(fresh_token))
            else:
                # Same token, force refresh
                token = refresh_token(creds)
                print(fetch_usage(token))
        else:
            raise
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
                            if (obj.status === 429) {
                                // 429: back off silently, never show error icon
                                console.warn("[ClaudeUsage] 429 rate limited, retry in 2min");
                                root._lastFetchTime = Date.now() + 60000;
                                retryTimer.interval = 120000;
                                retryTimer.restart();
                            } else if (!root.hasData) {
                                root.error = true;
                                root.errorMessage = obj.error;
                                console.warn("[ClaudeUsage] Startup fetch failed, retrying in 10s");
                                retryTimer.interval = 10000;
                                retryTimer.restart();
                            } else {
                                console.warn(`[ClaudeUsage] Error (keeping stale data): ${obj.error}`);
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

    // Retry quickly on startup failures (e.g. network not ready yet)
    Timer {
        id: retryTimer
        running: false
        repeat: false
        interval: 10000  // overridden dynamically
        onTriggered: {
            root._lastFetchTime = 0;  // clear backoff so refresh() won't throttle
            root.refresh();
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
