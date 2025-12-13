#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/vconfig.sh"

mkdir -p "$LOCAL_STATUS_DIR"

STATUS_JSON="${LOCAL_STATUS:-$LOCAL_STATUS_DIR/status.json}"
CONFLICTS_JSON="${LOCAL_CONFLICTS:-$LOCAL_STATUS_DIR/conflicts.json}"
OUT_HTML="$LOCAL_STATUS_DIR/dashboard.html"

# Safe reads (files may not exist yet)
STATUS_RAW="{}"
CONFLICTS_RAW="{}"
if [ -f "$STATUS_JSON" ]; then STATUS_RAW="$(cat "$STATUS_JSON")"; fi
if [ -f "$CONFLICTS_JSON" ]; then CONFLICTS_RAW="$(cat "$CONFLICTS_JSON")"; fi

# Minimal json extraction without jq (best-effort)
get_json_value() {
  local key="$1"
  local src="$2"
  # grabs "key": "value" OR "key": true/false
  echo "$src" | sed -nE "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"?([^\",}]*)\"?.*/\1/p" | head -n 1
}

ts="$(get_json_value timestamp "$STATUS_RAW")"
mode="$(get_json_value mode "$STATUS_RAW")"
status="$(get_json_value status "$STATUS_RAW")"
sync_mode="$(get_json_value mode "$STATUS_RAW")"

conflict="$(get_json_value conflict "$CONFLICTS_RAW")"
local_hash="$(get_json_value local_hash "$CONFLICTS_RAW")"
remote_hash="$(get_json_value remote_hash "$CONFLICTS_RAW")"
conf_ts="$(get_json_value timestamp "$CONFLICTS_RAW")"

# Defaults
[ -z "$ts" ] && ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
[ -z "$mode" ] && mode="${SYNC_MODE:-unknown}"
[ -z "$status" ] && status="unknown"
[ -z "$conflict" ] && conflict="unknown"

cat <<HTML > "$OUT_HTML"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Vireoka Sync Dashboard</title>
  <style>
    :root{
      --bg:#070B16; --panel:#0F1533; --panel2:#121A3A;
      --text:#FFFFFF; --muted:#C7CBD4; --border:rgba(255,255,255,.08);
      --purple:#5A2FE3; --teal:#3AF4D3; --gold:#E4B448;
      --grad: linear-gradient(90deg,#0A1A4A,#5A2FE3,#E4B448);
      --shadow: 0 8px 30px rgba(0,0,0,.35);
    }
    body{margin:0;background:radial-gradient(900px circle at 20% 30%, rgba(90,47,227,.35), transparent 55%),
                         radial-gradient(800px circle at 75% 75%, rgba(58,244,211,.20), transparent 60%),
                         linear-gradient(180deg,#0A1A4A,#070B16);
         color:var(--text); font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;}
    .wrap{max-width:1100px;margin:0 auto;padding:28px;}
    .hero{background:var(--grad); border:1px solid var(--border); border-radius:18px; padding:20px 22px; box-shadow:var(--shadow); overflow:hidden; position:relative;}
    .hero:after{content:"";position:absolute;inset:-40px;background:repeating-radial-gradient(circle at 30% 40%, rgba(255,255,255,.06) 0 1px, transparent 1px 18px);
                opacity:.18;mix-blend-mode:overlay;pointer-events:none;}
    h1{margin:0;font-size:28px;letter-spacing:-.02em}
    .sub{color:rgba(255,255,255,.85);margin-top:6px}
    .grid{display:grid;grid-template-columns:1.2fr .8fr;gap:18px;margin-top:18px}
    .card{background:linear-gradient(180deg, rgba(27,34,53,.92), rgba(15,21,51,.78)); border:1px solid var(--border); border-radius:18px; padding:18px; box-shadow:var(--shadow)}
    .k{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.08em}
    .v{font-size:16px;margin-top:6px}
    .pill{display:inline-flex;align-items:center;gap:10px;padding:8px 12px;border-radius:999px;border:1px solid var(--border);background:rgba(0,0,0,.15)}
    .dot{width:10px;height:10px;border-radius:99px;background:var(--teal);box-shadow:0 0 16px rgba(58,244,211,.45)}
    .dot.warn{background:var(--gold);box-shadow:0 0 18px rgba(228,180,72,.55)}
    .dot.bad{background:#EF4444;box-shadow:0 0 18px rgba(239,68,68,.45)}
    .mono{font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size:12px; color:rgba(255,255,255,.88); word-break:break-all}
    .row{display:grid;grid-template-columns: 180px 1fr;gap:12px;margin-top:12px;align-items:start}
    .hr{height:1px;background:linear-gradient(90deg,transparent,rgba(255,255,255,.14),transparent);margin:16px 0}
    .footer{color:rgba(255,255,255,.68);margin-top:16px;font-size:12px}
    @media (max-width: 900px){ .grid{grid-template-columns:1fr} }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="hero">
      <h1>Vireoka Sync Dashboard</h1>
      <div class="sub">Local: <span class="mono">${LOCAL_ROOT}</span> • Remote: <span class="mono">${REMOTE_HOST}:${REMOTE_ROOT}</span></div>
    </div>

    <div class="grid">
      <div class="card">
        <div class="k">Last Status</div>
        <div class="row"><div class="k">Timestamp</div><div class="v mono">${ts}</div></div>
        <div class="row"><div class="k">Mode</div><div class="v">${mode}</div></div>
        <div class="row"><div class="k">Sync</div><div class="v">${SYNC_MODE}</div></div>
        <div class="row"><div class="k">Local Themes</div><div class="v mono">${LOCAL_THEMES:-$LOCAL_ROOT/wp-content/themes}</div></div>
        <div class="row"><div class="k">Local Plugins</div><div class="v mono">${LOCAL_PLUGINS:-$LOCAL_ROOT/wp-content/plugins}</div></div>
        <div class="row"><div class="k">Local Uploads</div><div class="v mono">${LOCAL_UPLOADS:-$LOCAL_ROOT/wp-content/uploads}</div></div>
        <div class="hr"></div>
        <div class="k">Health</div>
        <div class="v">
          <span class="pill">
            <span class="dot"></span>
            <span>Status: <b>${status}</b></span>
          </span>
        </div>
      </div>

      <div class="card">
        <div class="k">Conflict Watch</div>
        <div class="v" style="margin-top:10px;">
HTML

# conflict pill
if [ "$conflict" = "true" ]; then
  cat <<'HTML' >> "$OUT_HTML"
          <span class="pill"><span class="dot warn"></span><span><b>Conflict detected</b></span></span>
HTML
elif [ "$conflict" = "false" ]; then
  cat <<'HTML' >> "$OUT_HTML"
          <span class="pill"><span class="dot"></span><span><b>No conflict</b></span></span>
HTML
else
  cat <<'HTML' >> "$OUT_HTML"
          <span class="pill"><span class="dot bad"></span><span><b>Unknown</b></span></span>
HTML
fi

cat <<HTML >> "$OUT_HTML"
        </div>
        <div class="row"><div class="k">Checked</div><div class="v mono">${conf_ts}</div></div>
        <div class="row"><div class="k">Local Hash</div><div class="v mono">${local_hash}</div></div>
        <div class="row"><div class="k">Remote Hash</div><div class="v mono">${remote_hash}</div></div>
        <div class="hr"></div>
        <div class="k">Artifacts</div>
        <div class="row"><div class="k">status.json</div><div class="v mono">${STATUS_JSON}</div></div>
        <div class="row"><div class="k">conflicts.json</div><div class="v mono">${CONFLICTS_JSON}</div></div>
        <div class="row"><div class="k">dashboard.html</div><div class="v mono">${OUT_HTML}</div></div>
      </div>
    </div>

    <div class="footer">Tip: open <span class="mono">${OUT_HTML}</span> in your browser. You can also publish it via a local web server if you want a live view.</div>
  </div>
</body>
</html>
HTML

echo "📊 HTML dashboard rendered: $OUT_HTML"
