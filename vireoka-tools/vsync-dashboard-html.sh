#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

# Optional secrets overlay
if [ -f "$BASE_DIR/vsecrets.sh" ]; then
  # shellcheck disable=SC1090
  source "$BASE_DIR/vsecrets.sh" >/dev/null 2>&1 || true
fi

mkdir -p "$LOCAL_STATUS_DIR"

DASH_HTML="$LOCAL_STATUS_DIR/dashboard.html"

cat <<'HTML' > "$DASH_HTML"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Vireoka Sync Dashboard</title>
  <style>
    :root {
      --bg: #070B16;
      --panel: rgba(27,34,53,.78);
      --border: rgba(255,255,255,.08);
      --text: #ffffff;
      --muted: #c7cbd4;
      --purple: #5A2FE3;
      --teal: #3AF4D3;
      --gold: #E4B448;
      --grad: linear-gradient(90deg,#0A1A4A,#5A2FE3,#E4B448);
      --grad2: linear-gradient(135deg,#5A2FE3,#3AF4D3);
      --shadow: 0 10px 30px rgba(0,0,0,.35);
    }
    *{box-sizing:border-box}
    body{
      margin:0; font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
      background: radial-gradient(900px circle at 20% 20%, rgba(90,47,227,.30), transparent 60%),
                  radial-gradient(900px circle at 80% 80%, rgba(58,244,211,.14), transparent 60%),
                  var(--bg);
      color:var(--text);
    }
    header{
      border-bottom:1px solid var(--border);
      background: rgba(7,11,22,.6);
      backdrop-filter: blur(14px);
    }
    .wrap{max-width:1120px;margin:0 auto;padding:24px}
    .brand{
      display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap;
    }
    .title{
      display:flex;flex-direction:column;gap:6px;
    }
    .title h1{
      margin:0;font-size:22px;letter-spacing:-.02em;
      background: var(--grad);
      -webkit-background-clip:text;background-clip:text;color:transparent;
      font-weight:800;
    }
    .title p{margin:0;color:var(--muted);font-size:13px}
    .pill{
      display:inline-flex;align-items:center;gap:10px;
      padding:10px 14px;border-radius:999px;border:1px solid var(--border);
      background: rgba(27,34,53,.50);
      box-shadow: var(--shadow);
      font-weight:700;
    }
    .dot{width:10px;height:10px;border-radius:999px;background:var(--teal);box-shadow:0 0 18px rgba(58,244,211,.45)}
    .dot.bad{background:#EF4444;box-shadow:0 0 18px rgba(239,68,68,.45)}
    main .grid{
      display:grid;grid-template-columns:repeat(12,1fr);gap:16px;margin-top:18px;
    }
    .card{
      grid-column: span 6;
      background: var(--panel);
      border:1px solid var(--border);
      border-radius:18px;
      padding:18px;
      box-shadow: var(--shadow);
      position:relative;
      overflow:hidden;
    }
    .card::after{
      content:"";
      position:absolute;inset:-40px;
      background: repeating-radial-gradient(circle at 30% 40%, rgba(255,255,255,.06) 0 1px, transparent 1px 18px);
      opacity:.12;pointer-events:none;
    }
    .card h2{margin:0 0 10px;font-size:14px;letter-spacing:.08em;text-transform:uppercase;color:rgba(255,255,255,.78)}
    .kv{display:grid;grid-template-columns:170px 1fr;gap:8px 14px;position:relative;z-index:1}
    .k{color:rgba(255,255,255,.70);font-size:13px}
    .v{color:#fff;font-weight:700;font-size:13px;word-break:break-word}
    .bar{
      height:3px;width:90px;border-radius:999px;background:var(--grad2);
      box-shadow:0 0 14px rgba(58,244,211,.22);margin-bottom:12px
    }
    .actions{display:flex;gap:10px;flex-wrap:wrap;margin-top:14px;position:relative;z-index:1}
    a.btn{
      display:inline-flex;align-items:center;justify-content:center;gap:10px;
      padding:10px 14px;border-radius:12px;border:1px solid var(--border);
      color:#fff;text-decoration:none;font-weight:800;
      background: rgba(15,21,51,.55);
      transition: transform .2s ease, border-color .2s ease;
    }
    a.btn:hover{transform:translateY(-1px);border-color:rgba(58,244,211,.35)}
    a.btn.primary{
      border:none;
      background: var(--grad2);
      box-shadow: 0 0 24px rgba(228,180,72,.22);
    }
    .small{font-size:12px;color:var(--muted)}
    pre{
      margin:0;
      background: rgba(15,21,51,.55);
      border:1px solid var(--border);
      border-radius:14px;
      padding:14px;
      overflow:auto;
      position:relative;z-index:1;
      color:#e5e7eb;
      font-size:12px;
      line-height:1.5;
    }
    @media (max-width: 900px){
      .card{grid-column: span 12}
      .kv{grid-template-columns: 1fr}
    }
  </style>
</head>
<body>
<header>
  <div class="wrap brand">
    <div class="title">
      <h1>Vireoka Sync Dashboard</h1>
      <p>Elite Neural Luxe • Local status + conflicts • Auto-generated</p>
    </div>
    <div class="pill" id="statusPill"><span class="dot" id="statusDot"></span><span id="statusText">Loading…</span></div>
  </div>
</header>

<main class="wrap">
  <div class="grid">
    <section class="card">
      <div class="bar"></div>
      <h2>Run Summary</h2>
      <div class="kv" id="summary"></div>
      <div class="actions">
        <a class="btn primary" href="./status.json" target="_blank" rel="noopener">Open status.json</a>
        <a class="btn" href="./conflicts.json" target="_blank" rel="noopener">Open conflicts.json</a>
      </div>
      <p class="small">Tip: host this folder with a simple server for clean fetch() access.</p>
    </section>

    <section class="card">
      <div class="bar"></div>
      <h2>Conflicts</h2>
      <pre id="conflictsPre">Loading…</pre>
      <div class="actions">
        <a class="btn" href="#" id="refreshBtn">Refresh</a>
      </div>
    </section>

    <section class="card">
      <div class="bar"></div>
      <h2>Quick Commands</h2>
      <pre id="cmds"></pre>
    </section>

    <section class="card">
      <div class="bar"></div>
      <h2>Notes</h2>
      <pre>
• If conflicts=true, run: ./vsync-ai-resolve.sh
• Dry-run mode: ./vsync.sh dry
• This dashboard reads ./status.json and ./conflicts.json in the same folder.
      </pre>
    </section>
  </div>
</main>

<script>
  const $ = (id) => document.getElementById(id);

  function row(k,v){
    const d = document.createElement('div');
    d.className='k'; d.textContent=k;
    const e = document.createElement('div');
    e.className='v'; e.textContent=v ?? '';
    return [d,e];
  }

  async function loadJson(url){
    const r = await fetch(url, {cache:'no-store'});
    if(!r.ok) throw new Error(`${url} ${r.status}`);
    return r.json();
  }

  async function render(){
    try{
      const status = await loadJson('./status.json');
      const conflicts = await loadJson('./conflicts.json').catch(()=>null);

      // Pill
      const ok = status.ok !== false && status.status !== 'error';
      $('statusDot').className = 'dot' + (ok ? '' : ' bad');
      $('statusText').textContent = ok ? 'OK' : 'ERROR';

      // Summary
      const box = $('summary');
      box.innerHTML='';
      [
        ['timestamp', status.timestamp || status.last_run || '—'],
        ['mode', status.mode || '—'],
        ['sync_mode', status.sync_mode || status.mode || '—'],
        ['local_root', status.local_root || '—'],
        ['remote_root', status.remote_root || '—'],
        ['remote_host', status.remote_host || '—'],
      ].forEach(([k,v]) => row(k,v).forEach(n => box.appendChild(n)));

      // Conflicts
      $('conflictsPre').textContent = conflicts ? JSON.stringify(conflicts, null, 2) : 'conflicts.json missing';

      // Commands
      const cmds = [
        './vsync.sh all',
        './vsync.sh themes',
        './vsync.sh plugins',
        './vsync.sh uploads',
        './vsync.sh dry',
        './vsync-ai-resolve.sh',
      ];
      $('cmds').textContent = cmds.join('\n');

    } catch(e){
      $('statusDot').className='dot bad';
      $('statusText').textContent='LOAD FAILED';
      $('conflictsPre').textContent = String(e);
    }
  }

  $('refreshBtn').addEventListener('click', (e)=>{ e.preventDefault(); render(); });
  render();
</script>
</body>
</html>
HTML

echo "📊 HTML dashboard written: $DASH_HTML"

# Best-effort publish to remote status dir (same folder as status.json)
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" >/dev/null 2>&1 || true
scp -P "$REMOTE_PORT" "$DASH_HTML" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS_DIR/dashboard.html" >/dev/null 2>&1 || true

echo "🌐 Remote publish (best effort): $REMOTE_STATUS_DIR/dashboard.html"
