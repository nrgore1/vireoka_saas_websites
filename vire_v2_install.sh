#!/usr/bin / env bash
set - e

echo "🚀 Installing Vire V2 (theme engine + canvas + Gutenberg styles + tokens + dashboard + CI + vault + AI conflict)"

# Must be run from: /mnt/c / Projects2025 / vireoka_website
ROOT = "vire-agent"
V2 = "$ROOT/v2"
THEME = "$V2/theme"
TOKENS = "$V2/tokens"
JS = "$V2/js"
GUT = "$V2/gutenberg"
DASH = "$V2/dashboard"
VAULT = "$V2/vault"
CI = "$V2/ci"
AI = "$V2/ai"
EXPORT = "$ROOT/export"
DEPLOY = "$ROOT/deploy"

mkdir - p "$THEME" "$TOKENS" "$JS" "$GUT" "$DASH" "$VAULT" "$CI" "$AI" "$EXPORT"

# =========================================================
# 1) Auto - assign body classes + per - product theming
# - Adds < body class="vire-site ..." > and data attributes
# =========================================================
  cat > "$THEME/bodyclass_inject.py" << 'PY'
#!/usr/bin / env python3
import json, re, pathlib, sys

def slugify(s: str) -> str:
s = s.strip().lower()
s = re.sub(r"[^a-z0-9\\s-]", "", s)
s = re.sub(r"\\s+", "-", s)
return s

site_path = pathlib.Path("site.json")
if not site_path.exists():
print("❌ site.json not found (run from repo root where site.json exists).")
sys.exit(1)

site = json.loads(site_path.read_text(encoding = "utf-8"))
site_id = slugify(site.get("site_id", "site"))
product = slugify(site.get("product_name", site.get("site_id", "product")))
tone = slugify(site.get("tone", "neural-luxe"))

pages_dir = pathlib.Path("vire-agent/export/pages")
if not pages_dir.exists():
print("❌ export/pages not found. Run export first.")
sys.exit(1)

for p in pages_dir.glob("*.html"):
  html = p.read_text(encoding = "utf-8")

    # Gutenberg export doesn't have <html>/<body>. We keep Gutenberg blocks, but wrap in a themed group wrapper.
wrapper_open = (
  f'<!-- wp:group {{"className":"vire-site vire-site--{site_id} vire-product--{product} vire-tone--{tone}","metadata":{{"name":"Vire Theme Wrapper"}}}} -->\\n'
        f'<div class="wp-block-group vire-site vire-site--{site_id} vire-product--{product} vire-tone--{tone}" '
        f'data-vire-site="{site_id}" data-vire-product="{product}" data-vire-tone="{tone}">\\n'
    )
wrapper_close = '\\n</div>\\n<!-- /wp:group -->\\n'

    # If already wrapped, skip
if 'class="wp-block-group vire-site' in html:
  continue

html = wrapper_open + html + wrapper_close
p.write_text(html, encoding = "utf-8")

print("✅ V2: Body classes injected into exported Gutenberg pages.")
PY
chmod + x "$THEME/bodyclass_inject.py"

# =========================================================
# 2) Inject animated neural canvas(lightweight JS)
# - Loads on pages that include.vire - site wrapper
# =========================================================
  cat > "$JS/neural-canvas.js" << 'JS'
    /*
      Vire Neural Canvas v1 (lightweight)
      - No dependencies
      - Respect prefers-reduced-motion
      - Auto-attaches behind hero sections if present
    */
    (function () {
      const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      if (reduce) return;

      function qs(sel, root = document) { return root.querySelector(sel); }
      function qsa(sel, root = document) { return Array.from(root.querySelectorAll(sel)); }

      const wrapper = qs('.vire-site');
      if (!wrapper) return;

      // Attach to first heading block area (or wrapper top)
      const anchor = qs('h1', wrapper) || wrapper;
      const host = document.createElement('div');
      host.className = 'vire-neural-host';
      anchor.parentNode.insertBefore(host, anchor);

      const c = document.createElement('canvas');
      c.className = 'vire-neural-canvas';
      host.appendChild(c);

      const ctx = c.getContext('2d', { alpha: true });

      function resize() {
        const w = Math.max(320, host.clientWidth);
        const h = Math.max(180, Math.min(520, Math.floor(window.innerHeight * 0.45)));
        c.width = Math.floor(w * devicePixelRatio);
        c.height = Math.floor(h * devicePixelRatio);
        c.style.width = w + 'px';
        c.style.height = h + 'px';
        ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
      }

      let t = 0;
      const nodes = [];
      function init() {
        nodes.length = 0;
        const w = host.clientWidth;
        const h = parseFloat(getComputedStyle(c).height);
        const n = Math.max(18, Math.min(42, Math.floor(w / 32)));
        for (let i = 0; i < n; i++) {
          nodes.push({
            x: Math.random() * w,
            y: Math.random() * h,
            vx: (Math.random() - 0.5) * 0.35,
            vy: (Math.random() - 0.5) * 0.25,
            r: 1 + Math.random() * 1.5
          });
        }
      }

      function colorVars() {
        const s = getComputedStyle(document.documentElement);
        return {
          purple: s.getPropertyValue('--v2-neural-purple').trim() || '#5A2FE3',
          teal: s.getPropertyValue('--v2-electric-teal').trim() || '#3AF4D3',
          gold: s.getPropertyValue('--v2-quantum-gold').trim() || '#E4B448'
        };
      }

      function step() {
        const w = host.clientWidth;
        const h = parseFloat(getComputedStyle(c).height);
        const { purple, teal, gold } = colorVars();

        ctx.clearRect(0, 0, w, h);

        // soft gradient haze
        const g = ctx.createLinearGradient(0, 0, w, h);
        g.addColorStop(0, 'rgba(90,47,227,0.16)');
        g.addColorStop(0.55, 'rgba(58,244,211,0.08)');
        g.addColorStop(1, 'rgba(228,180,72,0.10)');
        ctx.fillStyle = g;
        ctx.fillRect(0, 0, w, h);

        // animate nodes
        for (const p of nodes) {
          p.x += p.vx;
          p.y += p.vy;
          if (p.x < -10) p.x = w + 10;
          if (p.x > w + 10) p.x = -10;
          if (p.y < -10) p.y = h + 10;
          if (p.y > h + 10) p.y = -10;
        }

        // connections
        ctx.lineWidth = 1;
        for (let i = 0; i < nodes.length; i++) {
          for (let j = i + 1; j < nodes.length; j++) {
            const a = nodes[i], b = nodes[j];
            const dx = a.x - b.x, dy = a.y - b.y;
            const d2 = dx * dx + dy * dy;
            if (d2 < 140 * 140) {
              const alpha = 1 - Math.sqrt(d2) / 140;
              ctx.strokeStyle = `rgba(90,47,227,${alpha * 0.18})`;
              ctx.beginPath();
              ctx.moveTo(a.x, a.y);
              ctx.lineTo(b.x, b.y);
              ctx.stroke();
            }
          }
        }

        // nodes
        for (const p of nodes) {
          const pulse = (Math.sin(t / 32 + p.x / 40) + 1) / 2;
          const rad = p.r + pulse * 1.2;

          ctx.beginPath();
          ctx.fillStyle = `rgba(58,244,211,${0.20 + pulse * 0.25})`;
          ctx.arc(p.x, p.y, rad, 0, Math.PI * 2);
          ctx.fill();

          ctx.beginPath();
          ctx.fillStyle = `rgba(228,180,72,${0.08 + pulse * 0.12})`;
          ctx.arc(p.x, p.y, rad * 2.1, 0, Math.PI * 2);
          ctx.fill();
        }

        t++;
        requestAnimationFrame(step);
      }

      resize();
      init();
      window.addEventListener('resize', () => { resize(); init(); }, { passive: true });
      requestAnimationFrame(step);
    })();
JS

# =========================================================
# 3) Gutenberg block styles(theme CSS that WordPress can load)
# - You can enqueue this later via a tiny plugin or theme functions.php
# =========================================================
  cat > "$GUT/gutenberg-v2.css" << 'CSS'
/* Vire Gutenberg Styles v2 (Elite Neural Luxe) */
:root{
  --v2 - deep - blue:#0A1A4A;
  --v2 - neural - purple:#5A2FE3;
  --v2 - quantum - gold: #E4B448;
  --v2 - midnight - slate:#1B2235;
  --v2 - mist - gray: #C7CBD4;
  --v2 - graphite:#3E465D;
  --v2 - electric - teal:#3AF4D3;

  --v2 - radius - md: 12px;
  --v2 - radius - lg: 20px;

  --v2 - shadow - gold: 0 0 32px rgba(228, 180, 72, .55);
  --v2 - shadow - purple: 0 0 18px rgba(90, 47, 227, .45);
  --v2 - shadow - panel: 0 8px 30px rgba(0, 0, 0, .28);
}

.vire - site{
  background: radial - gradient(1200px 600px at 20 % -10 %, rgba(90, 47, 227, .25), transparent 60 %),
    radial - gradient(900px 520px at 90 % 40 %, rgba(58, 244, 211, .10), transparent 55 %),
    linear - gradient(180deg, rgba(10, 26, 74, 1), rgba(3, 10, 26, 1));
  color: #fff;
  padding: 42px 18px;
  border - radius: 18px;
}

.vire - site h1, .vire - site h2, .vire - site h3{
  letter - spacing: -0.02em;
}

.vire - site h1{
  font - size: clamp(34px, 5vw, 64px);
  margin: 6px 0 12px;
}

.vire - site p{
  color: rgba(255, 255, 255, .86);
  font - size: 16px;
  line - height: 1.7;
  max - width: 74ch;
}

.vire - neural - host{
  position: relative;
  margin: 10px 0 22px;
  border - radius: var(--v2 - radius - lg);
  overflow: hidden;
  border: 1px solid rgba(62, 70, 93, .70);
  box - shadow: var(--v2 - shadow - panel);
}
.vire - neural - canvas{
  display: block;
  width: 100 %;
  height: 320px;
}
@media(max - width: 720px) {
  .vire - neural - canvas{ height: 220px; }
}

.vire - card{
  background: rgba(27, 34, 53, .60);
  border: 1px solid rgba(62, 70, 93, .75);
  border - radius: var(--v2 - radius - lg);
  padding: 18px;
  box - shadow: var(--v2 - shadow - panel);
}

.vire - cta{
  display: inline - flex;
  align - items: center;
  gap: 10px;
  padding: 12px 16px;
  border - radius: var(--v2 - radius - md);
  background: linear - gradient(135deg, var(--v2 - neural - purple), var(--v2 - electric - teal));
  color: #fff;
  text - decoration: none;
  box - shadow: var(--v2 - shadow - gold);
  transition: transform .15s ease, filter .15s ease;
}
.vire - cta:hover{ transform: translateY(-1px) scale(1.01); filter: brightness(1.03); }

.vire - badge{
  display: inline - block;
  padding: 4px 10px;
  border - radius: 999px;
  border: 1px solid rgba(228, 180, 72, .55);
  background: rgba(228, 180, 72, .10);
  color: rgba(255, 255, 255, .92);
  font - size: 12px;
}
CSS

# =========================================================
# 4) Figma → CSS token parity(single source of truth)
# =========================================================
  cat > "$TOKENS/figma_tokens.json" << 'JSON'
{
  "colors": {
    "deepBlue": "#0A1A4A",
      "neuralPurple": "#5A2FE3",
        "quantumGold": "#E4B448",
          "midnightSlate": "#1B2235",
            "pureWhite": "#FFFFFF",
              "softIndigo": "#7C5CFF",
                "mistGray": "#C7CBD4",
                  "graphite": "#3E465D",
                    "electricTeal": "#3AF4D3"
  },
  "typography": {
    "headingFont": "Inter Tight",
      "bodyFont": "Inter",
        "monoFont": "JetBrains Mono",
          "scale": {
      "h1": 64,
        "h2": 48,
          "h3": 36,
            "h4": 24,
              "bodyL": 18,
                "bodyM": 16,
                  "bodyS": 14
    }
  },
  "spacing": [4, 8, 16, 24, 32, 48, 64, 96, 128],
    "radii": { "md": 12, "lg": 20 },
  "shadows": {
    "goldGlow": "0px 0px 32px rgba(228, 180, 72, 0.55)",
      "purpleGlow": "0px 0px 18px rgba(90, 47, 227, 0.45)",
        "panel": "0px 8px 30px rgba(0,0,0,0.28)"
  }
}
JSON

cat > "$TOKENS/figma_tokens.css" << 'CSS'
/* Auto-generated parity file (Vire V2) */
:root{
  --v2 - deep - blue:#0A1A4A;
  --v2 - neural - purple:#5A2FE3;
  --v2 - quantum - gold: #E4B448;
  --v2 - midnight - slate:#1B2235;
  --v2 - pure - white: #FFFFFF;
  --v2 - soft - indigo:#7C5CFF;
  --v2 - mist - gray: #C7CBD4;
  --v2 - graphite:#3E465D;
  --v2 - electric - teal:#3AF4D3;

  --v2 - h1: 64px; --v2 - h2: 48px; --v2 - h3: 36px; --v2 - h4: 24px;
  --v2 - body - l: 18px; --v2 - body - m: 16px; --v2 - body - s: 14px;

  --v2 - space - 4: 4px; --v2 - space - 8: 8px; --v2 - space - 16: 16px; --v2 - space - 24: 24px;
  --v2 - space - 32: 32px; --v2 - space - 48: 48px; --v2 - space - 64: 64px; --v2 - space - 96: 96px; --v2 - space - 128: 128px;

  --v2 - radius - md: 12px;
  --v2 - radius - lg: 20px;

  --v2 - shadow - gold: 0px 0px 32px rgba(228, 180, 72, 0.55);
  --v2 - shadow - purple: 0px 0px 18px rgba(90, 47, 227, 0.45);
  --v2 - shadow - panel: 0px 8px 30px rgba(0, 0, 0, 0.28);
}
CSS

cat > "$TOKENS/sync_tokens.py" << 'PY'
#!/usr/bin / env python3
import json, pathlib

src = pathlib.Path(__file__).parent / "figma_tokens.json"
out = pathlib.Path(__file__).parent / "figma_tokens.css"

t = json.loads(src.read_text(encoding = "utf-8"))
c = t["colors"]
ty = t["typography"]["scale"]
sp = t["spacing"]
r = t["radii"]
sh = t["shadows"]

css = f"""/* Auto-generated parity file (Vire V2) */
:root{
  {
    --v2 - deep - blue: { c["deepBlue"] };
    --v2 - neural - purple: { c["neuralPurple"] };
    --v2 - quantum - gold: { c["quantumGold"] };
    --v2 - midnight - slate: { c["midnightSlate"] };
    --v2 - pure - white: { c["pureWhite"] };
    --v2 - soft - indigo: { c["softIndigo"] };
    --v2 - mist - gray: { c["mistGray"] };
    --v2 - graphite: { c["graphite"] };
    --v2 - electric - teal: { c["electricTeal"] };

    --v2 - h1: { ty["h1"] } px; --v2 - h2: { ty["h2"] } px; --v2 - h3: { ty["h3"] } px; --v2 - h4: { ty["h4"] } px;
    --v2 - body - l: { ty["bodyL"] } px; --v2 - body - m: { ty["bodyM"] } px; --v2 - body - s: { ty["bodyS"] } px;

    --v2 - space - 4: { sp[0] } px; --v2 - space - 8: { sp[1] } px; --v2 - space - 16: { sp[2] } px; --v2 - space - 24: { sp[3] } px;
    --v2 - space - 32: { sp[4] } px; --v2 - space - 48: { sp[5] } px; --v2 - space - 64: { sp[6] } px; --v2 - space - 96: { sp[7] } px; --v2 - space - 128: { sp[8] } px;

    --v2 - radius - md: { r["md"] } px;
    --v2 - radius - lg: { r["lg"] } px;

    --v2 - shadow - gold: { sh["goldGlow"] };
    --v2 - shadow - purple: { sh["purpleGlow"] };
    --v2 - shadow - panel: { sh["panel"] };
  }
}
"""
out.write_text(css, encoding = "utf-8")
print("✅ Tokens synced:", out)
PY
chmod + x "$TOKENS/sync_tokens.py"

# =========================================================
# 5) Investor - ready PDF theme scaffold(LaTeX + HTML)
# =========================================================
  cat > "$V2/investor_memo/README.md" << 'MD'
# Investor Memo Theme(Vire V2)

Two outputs:
1)`memo.tex`(LaTeX) — investor - quality memo
2)`memo.html` — web version(same structure)

Next: wire real product content + numbers.
  MD
mkdir - p "$V2/investor_memo"

cat > "$V2/investor_memo/memo.tex" << 'TEX'
\documentclass[11pt]{ article }
\usepackage[margin = 1in]{ geometry }
\usepackage{ hyperref }
\usepackage{ graphicx }
\usepackage{ xcolor }
\definecolor{ DeepBlue } { HTML } { 0A1A4A }
\definecolor{ NeuralPurple } { HTML } { 5A2FE3 }
\definecolor{ QuantumGold } { HTML } { E4B448 }

\title{ \textbf{Vireoka LLC — Investor Memorandum } \\\large Elite Neural Luxe }
\author{ Founder: Narendra Gore }
\date{ \today }

\begin{ document }
\maketitle
\begin{ center }
\textcolor{ DeepBlue } { \rule{ 0.9\linewidth } { 0.6pt } }
\end{ center }

\section * { Executive Summary }
Vireoka is building a multi - product AI platform with an agent - first architecture spanning: LLM intelligence(AtmaSphere), communication mastery, niche community / dating engines, memoir creation, FinOps automation, and quantum - secure finance.

\section * { Market Thesis }
Agents shift software from tools to outcomes.Vireoka’s portfolio compounds distribution and data advantages across products.

\section * { Product Suite }
\begin{ itemize }
\item AtmaSphere LLM
\item Communication Suite
\item Dating Platform Builder
\item Memoir Studio
\item FinOps AI
\item Quantum - Secure Stablecoin
\end{ itemize }

\section * { Technology Architecture }
Core themes: modular services, secure data handling, RAG / retrieval, agent orchestration, observability.

\section * { Risk \& Compliance}
Stablecoin disclosure and risk framing for YMYL contexts; strong governance, security posture, and auditability.

\section * { Fundraising Ask }
Target: seed financing to accelerate productization, distribution, and enterprise partnerships.

\end{ document }
TEX

cat > "$V2/investor_memo/memo.html" << 'HTML'
  < !doctype html >
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <title>Vireoka — Investor Memorandum</title>
        <style>
          body{font - family:Inter,system-ui,Segoe UI,Arial,sans-serif;margin:0;background:#0A1A4A;color:#fff;}
          .wrap{max - width:980px;margin:0 auto;padding:48px 18px;}
          h1{letter - spacing:-.02em;margin:0 0 10px;}
          h2{margin - top:34px;}
          .rule{height:1px;background:rgba(255,255,255,.18);margin:18px 0 26px;}
          .card{background:rgba(27,34,53,.62);border:1px solid rgba(62,70,93,.75);border-radius:18px;padding:18px;}
          a{color:#3AF4D3;}
        </style>
      </head>
      <body>
        <div class="wrap">
          <h1>Vireoka LLC — Investor Memorandum</h1>
          <div class="rule"></div>

          <div class="card">
            <h2>Executive Summary</h2>
            <p>Vireoka is building a multi-product AI platform with an agent-first architecture.</p>

            <h2>Market Thesis</h2>
            <p>Agents shift software from tools to outcomes. Vireoka compounds distribution across products.</p>

            <h2>Product Suite</h2>
            <ul>
              <li>AtmaSphere LLM</li>
              <li>Communication Suite</li>
              <li>Dating Platform Builder</li>
              <li>Memoir Studio</li>
              <li>FinOps AI</li>
              <li>Quantum-Secure Stablecoin</li>
            </ul>

            <h2>Fundraising Ask</h2>
            <p>Seed financing to accelerate productization, distribution, and enterprise partnerships.</p>
          </div>
        </div>
      </body>
    </html>
HTML

# =========================================================
# 6) HTML dashboard renderer(sync status + build status)
# =========================================================
  cat > "$DASH/render_dashboard.py" << 'PY'
#!/usr/bin / env python3
import json, pathlib, datetime

# Reads:
# - ../.. (repo) / vireoka_local / _sync_status / status.json(if present)
# - export /pages/(count)
# - export/styles.css (exists)

root = pathlib.Path(__file__).resolve().parents[2]  # repo root(vire - agent / v2 / dashboard -> repo)
local_status = root / "vireoka_local" / "_sync_status" / "status.json"
conflicts = root / "vireoka_local" / "_sync_status" / "conflicts.json"

pages_dir = root / "vire-agent" / "export" / "pages"
css_file = root / "vire-agent" / "export" / "styles.css"

def read_json(p):
if p.exists():
  return json.loads(p.read_text(encoding = "utf-8"))
return None

status = read_json(local_status) or { }
conf = read_json(conflicts) or { "conflicts": [] }

pages = list(pages_dir.glob("*.html")) if pages_dir.exists() else[]
now = datetime.datetime.utcnow().isoformat() + "Z"

html = f"""<!doctype html>
  < html >
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Vireoka Dashboard</title>
  <style>
    body{{font-family:Inter,system-ui,Segoe UI,Arial,sans-serif;background:#0A1A4A;color:#fff;margin:0}}
    .wrap{{max-width:1100px;margin:0 auto;padding:24px 16px}}
    .grid{{display:grid;grid-template-columns:repeat(12,1fr);gap:14px}}
    .card{{grid-column:span 6;background:rgba(27,34,53,.62);border:1px solid rgba(62,70,93,.75);border-radius:18px;padding:14px}}
    .card.full{{grid-column:span 12}}
    .k{{opacity:.72;font-size:12px}}
    .v{{font-size:14px}}
    .badge{{display:inline-block;padding:3px 10px;border-radius:999px;background:rgba(228,180,72,.12);border:1px solid rgba(228,180,72,.55)}}
    a{{color:#3AF4D3}}
  </style>
</head>
<body>
<div class="wrap">
  <h1>Vireoka — Local Dashboard</h1>
  <div class="grid">
    <div class="card">
      <div class="k">Rendered</div><div class="v">{now}</div>
      <div class="k">Exported pages</div><div class="v">{len(pages)}</div>
      <div class="k">CSS built</div><div class="v">{'yes' if css_file.exists() else 'no'}</div>
    </div>
    <div class="card">
      <div class="k">Last sync</div><div class="v">{status.get('last_run','(none)')}</div>
      <div class="k">Mode</div><div class="v">{status.get('mode','(none)')}</div>
      <div class="k">Remote</div><div class="v">{status.get('remote_host','(none)')}</div>
    </div>
    <div class="card full">
      <div class="k">Conflicts</div>
      <div class="v">{len(conf.get('conflicts',[]))} <span class="badge">review</span></div>
      <pre style="white-space:pre-wrap;opacity:.9;margin-top:10px">{json.dumps(conf, indent=2)}</pre>
    </div>
  </div>
</div>
</body>
</html >
  """

out = pathlib.Path(__file__).parent / "dashboard.html"
out.write_text(html, encoding = "utf-8")
print("✅ Dashboard written:", out)
PY
chmod + x "$DASH/render_dashboard.py"

# =========================================================
# 7) Secrets vault support(simple.env vault with optional gpg)
# =========================================================
  cat > "$VAULT/vault.sh" << 'SH'
#!/usr/bin / env bash
set - euo pipefail

# Minimal secrets vault:
# - stores secrets in vire - agent / v2 / vault /.vault.env(gitignored)
# - optionally encrypt / decrypt with gpg if available

BASE_DIR = "$(cd "$(dirname "$0")" && pwd)"
VAULT_FILE = "$BASE_DIR/.vault.env"
ENC_FILE = "$BASE_DIR/.vault.env.gpg"

cmd = "${1:-help}"

ensure_gitignore() {
  local gi
  gi = "$(cd "$BASE_DIR /../.." && pwd)/.gitignore"
  touch "$gi"
  grep - q "^vire-agent/v2/vault/.vault.env$" "$gi" 2 > /dev/null || echo "vire-agent/v2/vault/.vault.env" >> "$gi"
  grep - q "^vire-agent/v2/vault/.vault.env.gpg$" "$gi" 2 > /dev/null || echo "vire-agent/v2/vault/.vault.env.gpg" >> "$gi"
}

case "$cmd" in
  init)
ensure_gitignore
if [! -f "$VAULT_FILE"]; then
cat > "$VAULT_FILE" << 'ENV'
# Vire Vault(local only)
# Example:
# OPENAI_API_KEY =...
# SLACK_WEBHOOK_URL =...
ENV
      chmod 600 "$VAULT_FILE"
      echo "✅ Created: $VAULT_FILE"
    else
      echo "✅ Exists: $VAULT_FILE"
fi
  ;;
  set)
ensure_gitignore
key = "${2:?key required}"
val = "${3:?value required}"
    touch "$VAULT_FILE"
    chmod 600 "$VAULT_FILE"
grep - v "^${key}=" "$VAULT_FILE" > "$VAULT_FILE.tmp" || true
    echo "${key}=${val}" >> "$VAULT_FILE.tmp"
    mv "$VAULT_FILE.tmp" "$VAULT_FILE"
    echo "✅ Set $key"
  ;;
  print)
[-f "$VAULT_FILE"] || { echo "❌ missing vault: $VAULT_FILE (run init)"; exit 1; }
    cat "$VAULT_FILE"
  ;;
  encrypt)
command - v gpg > /dev/null 2 >& 1 || { echo "❌ gpg not found"; exit 1; }
[-f "$VAULT_FILE" ] || { echo "❌ missing vault: $VAULT_FILE"; exit 1; }
gpg--yes--batch--output "$ENC_FILE" --symmetric "$VAULT_FILE"
    echo "✅ Encrypted: $ENC_FILE"
  ;;
  decrypt)
command - v gpg > /dev/null 2 >& 1 || { echo "❌ gpg not found"; exit 1; }
[-f "$ENC_FILE" ] || { echo "❌ missing encrypted vault: $ENC_FILE"; exit 1; }
gpg--yes--batch--output "$VAULT_FILE" --decrypt "$ENC_FILE"
    chmod 600 "$VAULT_FILE"
    echo "✅ Decrypted: $VAULT_FILE"
  ;;
help |*)
cat << 'HELP'
Usage: ./ vire - agent / v2 / vault / vault.sh < command >

  Commands:
  init                  Create local vault file + gitignore rules
  set KEY VALUE         Set a secret
  print                 Print vault contents
  encrypt               Encrypt vault to.vault.env.gpg(requires gpg)
  decrypt               Decrypt.vault.env.gpg back to.vault.env(requires gpg)
HELP
  ;;
esac
SH
chmod + x "$VAULT/vault.sh"

# =========================================================
# 8) CI validation hook(local + GitHub Actions scaffold)
# =========================================================
  cat > "$CI/validate.sh" << 'SH'
#!/usr/bin / env bash
set - euo pipefail

echo "🧪 Vire CI validation"

# 1) Ensure key files exist
req = (
  "vire-agent/cli/vire"
  "vire-agent/export/wp_static_export.py"
"vire-agent/v2/js/neural-canvas.js"
"vire-agent/v2/gutenberg/gutenberg-v2.css"
"vire-agent/v2/tokens/figma_tokens.json"
)
for f in "${req[@]}"; do
  [-f "$f"] || { echo "❌ Missing: $f"; exit 1; }
done

# 2) Ensure token CSS can be regenerated
python3 vire - agent / v2 / tokens / sync_tokens.py > /dev/null

# 3) Basic export smoke test(does not require WP)
cat > site.json << 'JSON'
{ "site_id": "ci-smoke", "product_name": "CI Smoke", "pages": ["Home", "Pricing", "Contact"] }
JSON
python3 vire - agent /export /wp_static_export.py >/dev / null

# 4) Inject wrappers
python3 vire - agent / v2 / theme / bodyclass_inject.py > /dev/null

echo "✅ CI validation passed"
SH
chmod + x "$CI/validate.sh"

mkdir - p.github / workflows
cat > ".github/workflows/vire_ci.yml" << 'YML'
name: Vire CI

on:
push:
pull_request:

jobs:
validate:
runs - on: ubuntu - latest
steps:
- uses: actions / checkout@v4
- uses: actions / setup - python@v5
with:
python - version: "3.11"
  - name: Validate
run: bash vire - agent / v2 / ci / validate.sh
YML

# =========================================================
# 9) AI - assisted conflict resolution(deterministic stub)
# - Reads _sync_status / conflicts.json(if present)
# - Outputs a recommended resolution plan json
# =========================================================
  cat > "$AI/resolve_conflicts.py" << 'PY'
#!/usr/bin / env python3
import json, pathlib, datetime

root = pathlib.Path(__file__).resolve().parents[2]  # repo root
conflicts_path = root / "vireoka_local" / "_sync_status" / "conflicts.json"
out_path = pathlib.Path(__file__).parent / "resolution_plan.json"

now = datetime.datetime.utcnow().isoformat() + "Z"

if not conflicts_path.exists():
plan = { "generated_at": now, "conflicts_found": 0, "recommendation": "none", "items": [] }
out_path.write_text(json.dumps(plan, indent = 2), encoding = "utf-8")
print("✅ No conflicts file found. Wrote empty plan:", out_path)
    raise SystemExit(0)

conf = json.loads(conflicts_path.read_text(encoding = "utf-8"))
items = conf.get("conflicts", [])

resolved = []
for it in items:
    # deterministic heuristics:
    # - prefer local for theme / css / js
    # - prefer remote for uploads / content
    path = (it.get("path") or "").lower()
if any(x in path for x in ["wp-content/themes", "wp-content/plugins", ".css", ".js"]):
  choice = "prefer_local"
reason = "code/theme assets should be controlled locally and deployed"
    elif "uploads" in path:
choice = "prefer_remote"
reason = "uploads typically authoritative on prod unless intentionally edited locally"
    else:
choice = "manual_review"
reason = "unknown category; require human/agent review"

resolved.append({
  "path": it.get("path"),
  "choice": choice,
  "reason": reason,
  "notes": "Upgrade: wire AtmaSphere/OpenAI to compare diffs & propose merge."
})

plan = {
  "generated_at": now,
  "conflicts_found": len(items),
  "recommendation": "apply_non_manual_then_review",
  "items": resolved
}

out_path.write_text(json.dumps(plan, indent = 2), encoding = "utf-8")
print("✅ Resolution plan written:", out_path)
PY
chmod + x "$AI/resolve_conflicts.py"

# =========================================================
# 10) WordPress enqueue helper(optional drop -in)
# - If you choose to load V2 styles + JS in WP
# =========================================================
  cat > "$V2/wp_enqueue_snippet.php" << 'PHP'
  <? php
// Add this to your theme's functions.php OR a tiny mu-plugin.
// Enqueues Vire V2 Gutenberg styles + neural canvas JS.

add_action('wp_enqueue_scripts', function () {
    $base = content_url('/uploads/vire-v2'); // or host these in theme assets
    wp_enqueue_style('vire-v2-tokens', $base. '/figma_tokens.css', [], null);
    wp_enqueue_style('vire-v2-gutenberg', $base. '/gutenberg-v2.css', ['vire-v2-tokens'], null);
    wp_enqueue_script('vire-v2-neural', $base. '/neural-canvas.js', [], null, true);
  });
PHP

# =========================================================
# 11) V2 runner(one command: export -> inject -> build -> dashboard)
# =========================================================
  cat > "$V2/vire_v2_run.sh" << 'SH'
#!/usr/bin / env bash
set - euo pipefail

echo "⚙️ Vire V2 Run"

# 1) Ensure token parity
python3 vire - agent / v2 / tokens / sync_tokens.py

# 2) Export Gutenberg pages from current./ site.json
python3 vire - agent /export/wp_static_export.py

# 3) Inject body classes wrapper
python3 vire - agent / v2 / theme / bodyclass_inject.py

# 4) Build CSS(if your build stack is ready)
if [-x "vire-agent/build/build.sh"]; then
  (cd vire - agent / build && ./ build.sh) || true
fi

# 5) Render dashboard
python3 vire - agent / v2 / dashboard / render_dashboard.py

echo "✅ V2 run complete."
echo "➡ Dashboard: vire-agent/v2/dashboard/dashboard.html"
SH
chmod + x "$V2/vire_v2_run.sh"

# =========================================================
# 12) Copy V2 assets into export/ (for easy hosting)
# =========================================================
  cat > "$V2/publish_assets.sh" << 'SH'
#!/usr/bin / env bash
set - euo pipefail

OUT = "vire-agent/export/v2_assets"
mkdir - p "$OUT"

cp - f vire - agent / v2 / tokens / figma_tokens.css "$OUT/figma_tokens.css"
cp - f vire - agent / v2 / gutenberg / gutenberg - v2.css "$OUT/gutenberg-v2.css"
cp - f vire - agent / v2 / js / neural - canvas.js "$OUT/neural-canvas.js"

echo "✅ Published V2 assets to: $OUT"
echo "Tip: upload these to WP (uploads/vire-v2) and enqueue using wp_enqueue_snippet.php"
SH
chmod + x "$V2/publish_assets.sh"

# =========================================================
# 13) Update root README with V2 usage
# =========================================================
  cat >> "$ROOT/README.md" << 'MD'

## Vire V2(Design + Canvas + Tokens + Dashboard)
Run full V2 pipeline:
```bash
# ensure site.json exists in repo root (or generated by Vire)
python3 vire-agent/v2/agent/prompt_to_site.py  # optional if you add your own
./vire-agent/v2/vire_v2_run.sh
Publish V2 assets for WordPress:

bash
Copy code
./vire-agent/v2/publish_assets.sh
Render local dashboard:

bash
Copy code
python3 vire-agent/v2/dashboard/render_dashboard.py
Validate (CI hook):

bash
Copy code
bash vire-agent/v2/ci/validate.sh
Vault:

bash
Copy code
./vire-agent/v2/vault/vault.sh init
./vire-agent/v2/vault/vault.sh set OPENAI_API_KEY your_key_here
AI conflict plan:

bash
Copy code
python3 vire-agent/v2/ai/resolve_conflicts.py
MD

echo
echo "✅ Vire V2 installed."
echo "-----------------------------------------"
echo "Next commands:"
echo "1) Create/ensure site.json in repo root"
echo "2) Run V2 pipeline: ./vire-agent/v2/vire_v2_run.sh"
echo "3) Publish V2 assets: ./vire-agent/v2/publish_assets.sh"
echo "4) View dashboard file: vire-agent/v2/dashboard/dashboard.html"
echo "5) CI validate: bash vire-agent/v2/ci/validate.sh"
