#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "=============================================="
echo "Vireoka Local Docker + Feature Scaffold Install"
echo "BASE_DIR:  $BASE_DIR"
echo "LOCAL_ROOT: $LOCAL_ROOT"
echo "=============================================="

# ----------------------------
# 0) Resolve local WP root
# ----------------------------
# Your canonical WP mirror is: .../vireoka_local/wp
# vconfig.sh (v5.1+) should already set LOCAL_ROOT to end with /wp
if [ ! -d "$LOCAL_ROOT/wp-content" ]; then
  echo "❌ Expected local wp-content not found at: $LOCAL_ROOT/wp-content"
  echo "   Fix LOCAL_ROOT in vconfig.sh to: /mnt/c/Projects2025/vireoka_website/vireoka_local/wp"
  exit 1
fi

mkdir -p "$BASE_DIR/local-docker"
mkdir -p "$BASE_DIR/local-docker/db"
mkdir -p "$BASE_DIR/local-docker/wp-cli"
mkdir -p "$LOCAL_ROOT/wp-content/plugins"

# ----------------------------
# 1) Docker Compose for local WP
# ----------------------------
cat <<'YML' > "$BASE_DIR/local-docker/docker-compose.yml"
services:
  db:
    image: mysql:8.0
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    ports:
      - "${MYSQL_PORT}:3306"
    volumes:
      - db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-uroot", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 5s
      timeout: 5s
      retries: 30

  wordpress:
    image: wordpress:php8.2-apache
    depends_on:
      db:
        condition: service_healthy
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "${WP_PORT}:80"
    volumes:
      # Mount your synced WordPress mirror
      - "${LOCAL_WP_MOUNT}:/var/www/html"

  wpcli:
    image: wordpress:cli
    depends_on:
      - wordpress
    user: "33:33"
    volumes:
      - "${LOCAL_WP_MOUNT}:/var/www/html"
    entrypoint: ["bash", "-lc", "wp --info && tail -f /dev/null"]

volumes:
  db_data:
YML

cat <<'ENV' > "$BASE_DIR/local-docker/.env"
# Local WordPress port
WP_PORT=8088

# MySQL exposed port (optional)
MYSQL_PORT=33306

# Local DB credentials (local-only)
MYSQL_DATABASE=wp_local
MYSQL_USER=wp
MYSQL_PASSWORD=wp
MYSQL_ROOT_PASSWORD=wp_root

# IMPORTANT: mount the local WP mirror folder
# This must point to your synced WP root:
# /mnt/c/Projects2025/vireoka_website/vireoka_local/wp
LOCAL_WP_MOUNT=/mnt/c/Projects2025/vireoka_website/vireoka_local/wp
ENV

# ----------------------------
# 2) Convenience scripts: up/down/reset/logs
# ----------------------------
cat <<'SH' > "$BASE_DIR/local-up.sh"
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)/local-docker"
docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" up -d
echo "✅ Local WP running at: http://localhost:8088"
SH
chmod +x "$BASE_DIR/local-up.sh"

cat <<'SH' > "$BASE_DIR/local-down.sh"
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)/local-docker"
docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" down
echo "🛑 Local WP stopped"
SH
chmod +x "$BASE_DIR/local-down.sh"

cat <<'SH' > "$BASE_DIR/local-reset.sh"
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)/local-docker"
docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" down -v
echo "🧹 Removed local containers + volumes"
SH
chmod +x "$BASE_DIR/local-reset.sh"

cat <<'SH' > "$BASE_DIR/local-logs.sh"
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)/local-docker"
docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" logs -f --tail=200
SH
chmod +x "$BASE_DIR/local-logs.sh"

# ----------------------------
# 3) DB Pull/Push using remote WP-CLI over SSH
#    (Assumes wp-cli works on Hostinger: you were using it already)
# ----------------------------
cat <<'SH' > "$BASE_DIR/vdb-pull.sh"
#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

STAMP="$(date +%Y%m%d_%H%M%S)"
DUMP_REMOTE="/tmp/vireoka_prod_${STAMP}.sql"
DUMP_LOCAL="$BASE_DIR/local-docker/db/prod_${STAMP}.sql"

echo "⬇️  Exporting PROD DB on remote via WP-CLI..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "cd '$REMOTE_ROOT' && wp db export '$DUMP_REMOTE' --allow-root"

echo "⬇️  Copying dump to local..."
scp -P "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST:$DUMP_REMOTE" "$DUMP_LOCAL" >/dev/null

echo "🧼 Cleaning remote temp dump..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "rm -f '$DUMP_REMOTE'" >/dev/null || true

echo "🗄  Importing into LOCAL docker WordPress..."
# Import into the running wordpress container
docker exec -i "$(docker ps --filter 'ancestor=wordpress:php8.2-apache' --format '{{.ID}}' | head -n 1)" \
  bash -lc "wp db import - --allow-root" < "$DUMP_LOCAL"

echo "🔁 Search-replace PROD URL -> LOCAL URL (best-effort)"
docker exec -i "$(docker ps --filter 'ancestor=wordpress:php8.2-apache' --format '{{.ID}}' | head -n 1)" \
  bash -lc "wp search-replace 'https://vireoka.com' 'http://localhost:8088' --skip-columns=guid --allow-root" || true

echo "✅ DB pull completed: $DUMP_LOCAL"
SH
chmod +x "$BASE_DIR/vdb-pull.sh"

cat <<'SH' > "$BASE_DIR/vdb-push.sh"
#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

STAMP="$(date +%Y%m%d_%H%M%S)"
DUMP_LOCAL="$BASE_DIR/local-docker/db/local_${STAMP}.sql"
DUMP_REMOTE="/tmp/vireoka_local_${STAMP}.sql"

echo "⬆️  Exporting LOCAL DB from docker..."
docker exec -i "$(docker ps --filter 'ancestor=wordpress:php8.2-apache' --format '{{.ID}}' | head -n 1)" \
  bash -lc "wp db export - --allow-root" > "$DUMP_LOCAL"

echo "⬆️  Uploading dump to remote..."
scp -P "$REMOTE_PORT" "$DUMP_LOCAL" "$REMOTE_USER@$REMOTE_HOST:$DUMP_REMOTE" >/dev/null

echo "🔁 Search-replace LOCAL URL -> PROD URL on remote dump (best-effort)..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
  "cd '$REMOTE_ROOT' && wp search-replace 'http://localhost:8088' 'https://vireoka.com' --skip-columns=guid --allow-root || true"

echo "⬆️  Importing into PROD (REMOTE) via WP-CLI..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "cd '$REMOTE_ROOT' && wp db import '$DUMP_REMOTE' --allow-root"

echo "🧼 Cleaning remote temp dump..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "rm -f '$DUMP_REMOTE'" >/dev/null || true

echo "✅ DB push completed (local -> prod). Dump saved: $DUMP_LOCAL"
SH
chmod +x "$BASE_DIR/vdb-push.sh"

# ----------------------------
# 4) Build Features NOW (as a real WP plugin)
#    This will sync via your existing plugins sync.
# ----------------------------
PLUGIN_DIR="$LOCAL_ROOT/wp-content/plugins/vireoka-enhancements"
mkdir -p "$PLUGIN_DIR/assets"

cat <<'PHP' > "$PLUGIN_DIR/vireoka-enhancements.php"
<?php
/**
 * Plugin Name: Vireoka Enhancements (Neural Luxe)
 * Description: Product body classes, neural canvas animation, Gutenberg styles, token parity helpers.
 * Version: 1.0.0
 * Author: Vireoka LLC
 */

if (!defined('ABSPATH')) exit;

class Vireoka_Enhancements {
  const VERSION = '1.0.0';

  public function __construct() {
    add_filter('body_class', [$this, 'body_classes']);
    add_action('wp_enqueue_scripts', [$this, 'enqueue_assets']);
    add_action('init', [$this, 'register_block_styles']);
  }

  /** Auto-assign body classes for product pages (by slug) */
  public function body_classes($classes) {
    if (!is_page()) return $classes;

    global $post;
    if (!$post) return $classes;

    $slug = $post->post_name;

    $map = [
      'atmasphere-llm'             => 'page-atmasphere',
      'communication-suite'        => 'page-communicationsuite',
      'dating-platform-builder'    => 'page-datingengine',
      'memoir-studio'              => 'page-memoirstudio',
      'finops-ai'                  => 'page-finopsai',
      'quantum-secure-stablecoin'  => 'page-quantumstablecoin',
      'agent-cloud-platform'       => 'page-agentcloud',
      'pricing'                    => 'page-pricing',
      'founder'                    => 'page-founder',
      'request-demo'               => 'page-requestdemo',
    ];

    if (isset($map[$slug])) $classes[] = $map[$slug];
    $classes[] = 'vireoka-neural-luxe';

    return $classes;
  }

  /** Enqueue lightweight neural canvas + (optional) Gutenberg style CSS */
  public function enqueue_assets() {
    // Canvas animation
    wp_enqueue_script(
      'vireoka-neural-canvas',
      plugins_url('assets/neural-canvas.js', __FILE__),
      [],
      self::VERSION,
      true
    );

    // Block styles (editor + front)
    wp_enqueue_style(
      'vireoka-block-styles',
      plugins_url('assets/blocks.css', __FILE__),
      [],
      self::VERSION
    );
  }

  /** Gutenberg block styles (no builder required) */
  public function register_block_styles() {
    if (!function_exists('register_block_style')) return;

    register_block_style('core/group', [
      'name'  => 'vireoka-card',
      'label' => 'Vireoka Card'
    ]);

    register_block_style('core/button', [
      'name'  => 'vireoka-neural',
      'label' => 'Neural Gradient'
    ]);

    register_block_style('core/columns', [
      'name'  => 'vireoka-feature-grid',
      'label' => 'Feature Grid (Neural Luxe)'
    ]);
  }
}

new Vireoka_Enhancements();
PHP

cat <<'JS' > "$PLUGIN_DIR/assets/neural-canvas.js"
(() => {
  // Lightweight, no dependencies. Renders a subtle animated neural field behind hero sections.
  // It only runs if a .vireoka-hero / .hero / .page-hero exists.
  const hero = document.querySelector('.vireoka-hero, .vireoka-hero-section, .hero, .page-hero');
  if (!hero) return;

  const canvas = document.createElement('canvas');
  canvas.setAttribute('aria-hidden', 'true');
  canvas.style.position = 'absolute';
  canvas.style.inset = '0';
  canvas.style.width = '100%';
  canvas.style.height = '100%';
  canvas.style.pointerEvents = 'none';
  canvas.style.opacity = '0.55';
  canvas.style.mixBlendMode = 'screen';
  canvas.style.zIndex = '1';

  hero.style.position = hero.style.position || 'relative';
  hero.insertBefore(canvas, hero.firstChild);

  const ctx = canvas.getContext('2d');
  let w = 0, h = 0, dpr = Math.max(1, Math.min(2, window.devicePixelRatio || 1));

  function resize() {
    const r = hero.getBoundingClientRect();
    w = Math.max(320, Math.floor(r.width));
    h = Math.max(220, Math.floor(r.height));
    canvas.width = Math.floor(w * dpr);
    canvas.height = Math.floor(h * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  window.addEventListener('resize', resize, { passive: true });
  resize();

  // Nodes
  const N = Math.min(70, Math.floor((w * h) / 18000));
  const nodes = Array.from({ length: N }, () => ({
    x: Math.random() * w,
    y: Math.random() * h,
    vx: (Math.random() - 0.5) * 0.25,
    vy: (Math.random() - 0.5) * 0.25,
  }));

  let t = 0;
  function frame() {
    t += 1;

    ctx.clearRect(0, 0, w, h);

    // Background fade
    ctx.globalAlpha = 0.35;
    ctx.fillStyle = '#0A1A4A';
    ctx.fillRect(0, 0, w, h);

    // Links
    ctx.globalAlpha = 0.55;
    for (let i = 0; i < nodes.length; i++) {
      const a = nodes[i];
      a.x += a.vx; a.y += a.vy;
      if (a.x < 0 || a.x > w) a.vx *= -1;
      if (a.y < 0 || a.y > h) a.vy *= -1;

      for (let j = i + 1; j < nodes.length; j++) {
        const b = nodes[j];
        const dx = a.x - b.x, dy = a.y - b.y;
        const dist = Math.hypot(dx, dy);
        if (dist < 160) {
          const alpha = (1 - dist / 160) * 0.35;
          // alternating violet/teal
          ctx.strokeStyle = ( (i + t) % 120 < 60 ) ? `rgba(90,47,227,${alpha})` : `rgba(58,244,211,${alpha})`;
          ctx.lineWidth = 1;
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.stroke();
        }
      }
    }

    // Nodes
    for (const n of nodes) {
      ctx.beginPath();
      ctx.fillStyle = 'rgba(228,180,72,.18)';
      ctx.arc(n.x, n.y, 1.6, 0, Math.PI * 2);
      ctx.fill();
    }

    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
})();
JS

cat <<'CSS' > "$PLUGIN_DIR/assets/blocks.css"
/* Gutenberg styles for Vireoka (front + editor) */
.is-style-vireoka-card {
  background: linear-gradient(180deg, rgba(27,34,53,.92), rgba(15,21,51,.78));
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 20px;
  box-shadow: 0 4px 24px rgba(0,0,0,.20);
  padding: 32px;
}

.wp-block-button.is-style-vireoka-neural .wp-block-button__link {
  background: linear-gradient(135deg, #5A2FE3, #3AF4D3);
  color: #fff !important;
  border-radius: 12px;
  padding: 14px 26px;
  font-weight: 700;
  box-shadow: 0 0 32px rgba(228,180,72,.55);
  border: 1px solid rgba(255,255,255,.08);
}

.wp-block-columns.is-style-vireoka-feature-grid {
  gap: 32px;
}
CSS

# ----------------------------
# 5) Figma → CSS token parity starter
# ----------------------------
TOK_DIR="$LOCAL_ROOT/wp-content/themes/_vireoka_tokens"
mkdir -p "$TOK_DIR"

cat <<'JSON' > "$TOK_DIR/figma.tokens.json"
{
  "colors": {
    "blueDeep": "#0A1A4A",
    "purpleNeural": "#5A2FE3",
    "goldQuantum": "#E4B448",
    "slateMidnight": "#1B2235",
    "whitePure": "#FFFFFF",
    "indigoSoft": "#7C5CFF",
    "grayMist": "#C7CBD4",
    "graphite": "#3E465D",
    "tealElectric": "#3AF4D3"
  },
  "gradients": {
    "neural": "linear-gradient(135deg, #5A2FE3, #3AF4D3)",
    "luxe": "linear-gradient(90deg, #0A1A4A, #5A2FE3, #E4B448)"
  },
  "type": {
    "heading": "Inter Tight",
    "body": "Inter",
    "mono": "JetBrains Mono"
  },
  "scale": {
    "h1": 64,
    "h2": 48,
    "h3": 36,
    "h4": 24,
    "bodyL": 18,
    "bodyM": 16,
    "bodyS": 14
  }
}
JSON

cat <<'CSS' > "$TOK_DIR/tokens.css"
/* Generated token parity file (starter). Keep in sync with figma.tokens.json */
:root{
  --blue-deep:#0A1A4A;
  --purple-neural:#5A2FE3;
  --gold-quantum:#E4B448;
  --slate-midnight:#1B2235;
  --white-pure:#FFFFFF;

  --indigo-soft:#7C5CFF;
  --gray-mist:#C7CBD4;
  --graphite:#3E465D;
  --teal-electric:#3AF4D3;

  --gradient-neural:linear-gradient(135deg,#5A2FE3,#3AF4D3);
  --gradient-luxe:linear-gradient(90deg,#0A1A4A,#5A2FE3,#E4B448);
}
CSS

# ----------------------------
# 6) Investor-ready PDF theme scaffold (LaTeX + HTML print CSS)
# ----------------------------
MEMO_DIR="$LOCAL_ROOT/wp-content/themes/_vireoka_investor_memo"
mkdir -p "$MEMO_DIR/latex" "$MEMO_DIR/html"

cat <<'TEX' > "$MEMO_DIR/latex/investor_memo.tex"
\documentclass[11pt]{article}
\usepackage[margin=1in]{geometry}
\usepackage{hyperref}
\usepackage{xcolor}
\usepackage{titlesec}
\usepackage{graphicx}
\usepackage{longtable}
\definecolor{VireokaBlue}{HTML}{0A1A4A}
\definecolor{VireokaPurple}{HTML}{5A2FE3}
\definecolor{VireokaGold}{HTML}{E4B448}

\titleformat{\section}{\Large\bfseries\color{VireokaBlue}}{}{0em}{}
\titleformat{\subsection}{\large\bfseries\color{VireokaPurple}}{}{0em}{}

\title{\textbf{Vireoka Investor Memorandum}\\\small Elite Neural Luxe Draft}
\author{Vireoka LLC}
\date{\today}

\begin{document}
\maketitle

\section{Executive Summary}
This is a scaffold. Replace with your 60-page memo content.

\section{Market Thesis}
\subsection{Agent Intelligence Trend}
\subsection{Why Now}

\section{Products}
\begin{itemize}
  \item AtmaSphere LLM
  \item Communication Suite
  \item Dating Platform Engine
  \item Memoir Studio
  \item FinOps AI
  \item Quantum-Secure Stablecoin
\end{itemize}

\section{Technology Architecture}
\section{Business Model}
\section{Financial Projections}
\section{Risks \& Mitigations}
\section{Fundraising Ask}

\end{document}
TEX

cat <<'SH' > "$MEMO_DIR/latex/build.sh"
#!/usr/bin/env bash
set -euo pipefail
# Requires a LaTeX install (or run inside a latex docker image)
pdflatex investor_memo.tex
pdflatex investor_memo.tex
echo "✅ Built investor_memo.pdf"
SH
chmod +x "$MEMO_DIR/latex/build.sh"

cat <<'HTML' > "$MEMO_DIR/html/investor_memo.html"
<!doctype html>
<html>
<head>
  <meta charset="utf-8"/>
  <title>Vireoka Investor Memo</title>
  <link rel="stylesheet" href="./print.css"/>
</head>
<body>
  <header>
    <h1>Vireoka Investor Memorandum</h1>
    <p class="sub">Elite Neural Luxe Draft</p>
  </header>

  <section>
    <h2>Executive Summary</h2>
    <p>Replace with your 60-page memo content.</p>
  </section>
</body>
</html>
HTML

cat <<'CSS' > "$MEMO_DIR/html/print.css"
@page { margin: 1in; }
body{ font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif; color:#0b1020; }
h1{ color:#0A1A4A; letter-spacing:-.02em; }
h2{ color:#5A2FE3; margin-top:28px; }
.sub{ color:#3E465D; }
CSS

echo "✅ Installed local-docker stack + feature scaffolds."
echo ""
echo "Next:"
echo "  1) Start local:   ./local-up.sh"
echo "  2) Pull DB:       ./vdb-pull.sh"
echo "  3) Activate plugin 'Vireoka Enhancements (Neural Luxe)' in WP Admin"
echo "  4) Sync to prod:  ./vsync.sh themes && ./vsync.sh plugins && ./vsync.sh uploads"
