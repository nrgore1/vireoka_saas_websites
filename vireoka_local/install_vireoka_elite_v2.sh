#!/usr/bin/env bash
set -e

BASE="./wp/wp-content"
THEME="$BASE/themes/vireoka"
MU="$BASE/mu-plugins"
ASSETS="$THEME/assets"
TOKENS="$THEME/tokens"
PDF="$THEME/investor-pdf"
PATTERNS="$THEME/patterns"

echo "⚡ Installing Vireoka Elite Neural Luxe v2..."

mkdir -p "$THEME" "$MU" "$ASSETS/js" "$ASSETS/css" "$TOKENS" "$PDF" "$PATTERNS"

# -------------------------------------------------
# 1) MU Plugin: Body classes + data attributes + product map
# -------------------------------------------------
cat <<'PHP' > "$MU/vireoka-runtime.php"
<?php
/**
 * Plugin Name: Vireoka Runtime Layer (Body Classes + Tokens)
 */

function vireoka_get_product_slug_map() {
  // Map WP page slugs → canonical product ids
  // Adjust/add as your slugs evolve.
  return [
    'atmasphere-llm' => 'atmasphere',
    'communication-suite' => 'comms',
    'dating-platform-builder' => 'dating',
    'memoir-studio' => 'memoir',
    'finops-ai' => 'finops',
    'quantum-secure-finance' => 'quantum',
    'quantum-secure-stablecoin' => 'quantum',
    'agent-cloud-platform' => 'agentcloud',
  ];
}

add_filter('body_class', function ($classes) {
  if (is_page()) {
    global $post;
    $slug = $post->post_name ?? '';
    $classes[] = 'vireoka';
    $classes[] = 'vireoka-page';
    if ($slug) $classes[] = 'vireoka-page-' . sanitize_html_class($slug);

    $map = vireoka_get_product_slug_map();
    if ($slug && isset($map[$slug])) {
      $classes[] = 'vireoka-product';
      $classes[] = 'vireoka-product-' . sanitize_html_class($map[$slug]);
    }
  }
  return $classes;
});

add_filter('language_attributes', function($output) {
  // Add a data attribute on <html> for CSS/JS targeting
  if (!is_page()) return $output;
  global $post;
  $slug = $post->post_name ?? '';
  if (!$slug) return $output;

  $map = vireoka_get_product_slug_map();
  $product = isset($map[$slug]) ? $map[$slug] : '';
  if ($product) {
    $output .= ' data-vireoka-product="' . esc_attr($product) . '"';
  }
  return $output;
});
PHP

# -------------------------------------------------
# 2) Tokens: CSS vars + Product overrides + Components
# -------------------------------------------------
cat <<'CSS' > "$TOKENS/design-tokens.css"
/* Vireoka Elite Neural Luxe — Design Tokens */
:root{
  /* Core palette */
  --v-deep-blue:#0A1A4A;
  --v-purple:#5A2FE3;
  --v-gold:#E4B448;
  --v-slate:#1B2235;
  --v-white:#FFFFFF;
  --v-graphite:#3E465D;
  --v-mist:#C7CBD4;
  --v-indigo:#7C5CFF;
  --v-teal:#3AF4D3;

  /* Gradients */
  --v-gradient-neural:linear-gradient(135deg,#5A2FE3,#3AF4D3);
  --v-gradient-luxe:linear-gradient(90deg,#0A1A4A,#5A2FE3,#E4B448);

  /* Typography */
  --v-font-heading:'Inter Tight',system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;
  --v-font-body:'Inter',system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;
  --v-font-mono:'JetBrains Mono',ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;

  /* Scale */
  --v-radius-sm:8px;
  --v-radius-md:12px;
  --v-radius-lg:20px;

  /* Shadows */
  --v-shadow-gold:0 0 32px rgba(228,180,72,.55);
  --v-shadow-purple:0 0 18px rgba(90,47,227,.45);
  --v-shadow-panel:0 4px 24px rgba(0,0,0,.20);

  /* Layout */
  --v-container:1120px;
  --v-pad:24px;

  /* Neural canvas behavior */
  --v-canvas-link:rgba(90,47,227,.35);
  --v-canvas-dot:rgba(228,180,72,.55);
  --v-canvas-strength:1; /* JS will modulate */
}

/* Product-specific token overrides */
html[data-vireoka-product="atmasphere"]{
  --v-canvas-link:rgba(58,244,211,.30);
}
html[data-vireoka-product="memoir"]{
  --v-canvas-link:rgba(228,180,72,.25);
  --v-canvas-dot:rgba(228,180,72,.70);
}
html[data-vireoka-product="finops"]{
  --v-canvas-link:rgba(124,92,255,.30);
}
html[data-vireoka-product="quantum"]{
  --v-canvas-link:rgba(90,47,227,.45);
  --v-canvas-dot:rgba(58,244,211,.55);
}
CSS

cat <<'CSS' > "$ASSETS/css/components.css"
/* Elite components (usable in Gutenberg + templates) */
.v-container{max-width:var(--v-container);margin:0 auto;padding:0 var(--v-pad);}
.v-hero{position:relative;overflow:hidden;border-radius:var(--v-radius-lg);box-shadow:var(--v-shadow-panel);background:rgba(27,34,53,.55);backdrop-filter:blur(10px);padding:64px 32px;}
.v-hero h1{font-family:var(--v-font-heading);font-weight:800;letter-spacing:-0.02em;font-size:clamp(36px,4vw,64px);margin:0 0 12px;}
.v-hero p{font-family:var(--v-font-body);font-size:18px;color:var(--v-mist);max-width:64ch;margin:0 0 24px;}
.v-btn{display:inline-flex;gap:10px;align-items:center;justify-content:center;border-radius:var(--v-radius-md);padding:12px 18px;font-weight:700;text-decoration:none;transition:transform .15s ease,box-shadow .15s ease,opacity .15s ease;}
.v-btn-primary{color:#fff;background:var(--v-gradient-neural);box-shadow:var(--v-shadow-gold);}
.v-btn-primary:hover{transform:translateY(-1px);opacity:.95;}
.v-btn-secondary{color:var(--v-indigo);border:2px solid var(--v-purple);background:transparent;}
.v-card{background:rgba(27,34,53,.70);border:1px solid var(--v-graphite);border-radius:var(--v-radius-lg);box-shadow:var(--v-shadow-panel);padding:20px;transition:transform .15s ease, box-shadow .15s ease;}
.v-card:hover{transform:scale(1.01);box-shadow:var(--v-shadow-purple),var(--v-shadow-panel);}
.v-grid{display:grid;gap:18px;}
@media(min-width:900px){.v-grid-3{grid-template-columns:repeat(3,minmax(0,1fr));}}
@media(max-width:899px){.v-hero{padding:40px 20px;}}
/* Canvas sits behind everything */
#vireoka-neural-canvas{position:fixed;inset:0;z-index:-1;opacity:.40;pointer-events:none;}
body{background:radial-gradient(1200px 700px at 20% 0%, rgba(90,47,227,.25), transparent 60%),
      radial-gradient(1200px 700px at 80% 20%, rgba(228,180,72,.15), transparent 55%),
      linear-gradient(180deg, var(--v-deep-blue), #070B1A 85%);}
CSS

# -------------------------------------------------
# 3) Neural Canvas v2: product color modes + scroll-reactive density
# -------------------------------------------------
cat <<'JS' > "$ASSETS/js/neural-canvas.v2.js"
(() => {
  const canvas = document.createElement('canvas');
  canvas.id = 'vireoka-neural-canvas';
  document.body.appendChild(canvas);
  const ctx = canvas.getContext('2d', { alpha: true });

  const css = getComputedStyle(document.documentElement);
  const linkColor = () => css.getPropertyValue('--v-canvas-link').trim() || 'rgba(90,47,227,.35)';
  const dotColor  = () => css.getPropertyValue('--v-canvas-dot').trim()  || 'rgba(228,180,72,.55)';

  let W=0,H=0;
  const resize = () => { W=canvas.width=window.innerWidth; H=canvas.height=window.innerHeight; };
  window.addEventListener('resize', resize); resize();

  const baseCount = 64;
  let nodes = [];
  const makeNodes = (count) => Array.from({length:count}, () => ({
    x: Math.random()*W, y: Math.random()*H,
    vx: (Math.random()-0.5)*0.45, vy:(Math.random()-0.5)*0.45
  }));
  nodes = makeNodes(baseCount);

  const clamp = (v,a,b)=>Math.max(a,Math.min(b,v));
  const scrollStrength = () => {
    const y = window.scrollY || 0;
    const max = Math.max(document.body.scrollHeight - H, 1);
    return clamp(y / max, 0, 1);
  };

  function tick(){
    const s = scrollStrength(); // 0..1
    const target = Math.round(baseCount + s * 40);
    if (nodes.length < target) nodes.push(...makeNodes(target - nodes.length));
    if (nodes.length > target) nodes = nodes.slice(0, target);

    ctx.clearRect(0,0,W,H);

    // Move
    for (const n of nodes){
      n.x += n.vx; n.y += n.vy;
      if (n.x < 0 || n.x > W) n.vx *= -1;
      if (n.y < 0 || n.y > H) n.vy *= -1;
    }

    // Links
    const maxD = 130 + s*40;
    ctx.lineWidth = 1;
    for (let i=0;i<nodes.length;i++){
      const a = nodes[i];
      for (let j=i+1;j<nodes.length;j++){
        const b = nodes[j];
        const dx=a.x-b.x, dy=a.y-b.y;
        const d = Math.hypot(dx,dy);
        if (d < maxD){
          const alpha = (1 - d/maxD) * (0.25 + s*0.35);
          ctx.strokeStyle = linkColor().replace(/rgba\(([^)]+)\)/, (m,inner)=>{
            const parts = inner.split(',').map(x=>x.trim());
            return `rgba(${parts[0]},${parts[1]},${parts[2]},${alpha.toFixed(3)})`;
          });
          ctx.beginPath(); ctx.moveTo(a.x,a.y); ctx.lineTo(b.x,b.y); ctx.stroke();
        }
      }
    }

    // Dots
    ctx.fillStyle = dotColor();
    for (const n of nodes){
      ctx.beginPath(); ctx.arc(n.x,n.y,1.3 + s*0.6,0,Math.PI*2); ctx.fill();
    }

    requestAnimationFrame(tick);
  }
  tick();
})();
JS

# -------------------------------------------------
# 4) Theme bootstrap: enqueue tokens + components + canvas + editor styles
# -------------------------------------------------
cat <<'PHP' > "$THEME/functions.php"
<?php
add_action('wp_enqueue_scripts', function () {
  $theme = get_template_directory_uri();

  // Tokens + components
  wp_enqueue_style('vireoka-tokens', $theme . '/tokens/design-tokens.css', [], null);
  wp_enqueue_style('vireoka-components', $theme . '/assets/css/components.css', ['vireoka-tokens'], null);

  // Canvas
  wp_enqueue_script('vireoka-neural', $theme . '/assets/js/neural-canvas.v2.js', [], null, true);
});

add_action('after_setup_theme', function () {
  add_theme_support('editor-styles');
  add_editor_style('tokens/design-tokens.css');
  add_editor_style('assets/css/components.css');
  add_theme_support('align-wide');
});

require_once __DIR__ . '/gutenberg.php';
PHP

# -------------------------------------------------
# 5) Gutenberg: block styles + patterns (Hero / Feature Grid / CTA)
# -------------------------------------------------
cat <<'PHP' > "$THEME/gutenberg.php"
<?php
add_action('init', function () {
  // Register block styles (core)
  if (function_exists('register_block_style')) {
    register_block_style('core/button', [
      'name'  => 'vireoka-primary',
      'label' => 'Vireoka Primary',
      'inline_style' => '.is-style-vireoka-primary .wp-element-button{background:var(--v-gradient-neural)!important;color:#fff!important;border-radius:var(--v-radius-md)!important;box-shadow:var(--v-shadow-gold)!important;font-weight:700;}'
    ]);

    register_block_style('core/group', [
      'name'  => 'vireoka-panel',
      'label' => 'Vireoka Panel',
      'inline_style' => '.is-style-vireoka-panel{background:rgba(27,34,53,.70)!important;border:1px solid var(--v-graphite)!important;border-radius:var(--v-radius-lg)!important;box-shadow:var(--v-shadow-panel)!important;padding:24px!important;}'
    ]);
  }

  // Register patterns (WP looks in /patterns automatically for block themes,
  // but for classic themes we register explicitly)
  if (function_exists('register_block_pattern')) {
    register_block_pattern('vireoka/hero', [
      'title' => 'Vireoka Hero',
      'content' => file_get_contents(__DIR__ . '/patterns/hero.php')
    ]);
    register_block_pattern('vireoka/feature-grid', [
      'title' => 'Vireoka Feature Grid',
      'content' => file_get_contents(__DIR__ . '/patterns/feature-grid.php')
    ]);
    register_block_pattern('vireoka/cta', [
      'title' => 'Vireoka CTA',
      'content' => file_get_contents(__DIR__ . '/patterns/cta.php')
    ]);
  }
});
PHP

cat <<'PAT' > "$PATTERNS/hero.php"
<!-- wp:group {"className":"v-hero v-container is-style-vireoka-panel"} -->
<div class="wp-block-group v-hero v-container is-style-vireoka-panel">
  <!-- wp:heading {"level":1} -->
  <h1>Vireoka — The AI-Agent Company</h1>
  <!-- /wp:heading -->
  <!-- wp:paragraph -->
  <p>Six premium products. One agent cloud. A luxury-grade technical platform built for outcomes.</p>
  <!-- /wp:paragraph -->
  <!-- wp:buttons -->
  <div class="wp-block-buttons">
    <!-- wp:button {"className":"is-style-vireoka-primary"} -->
    <div class="wp-block-button is-style-vireoka-primary"><a class="wp-block-button__link wp-element-button">Explore Products</a></div>
    <!-- /wp:button -->
    <!-- wp:button -->
    <div class="wp-block-button"><a class="wp-block-button__link wp-element-button">Request Demo</a></div>
    <!-- /wp:button -->
  </div>
  <!-- /wp:buttons -->
</div>
<!-- /wp:group -->
PAT

cat <<'PAT' > "$PATTERNS/feature-grid.php"
<!-- wp:group {"className":"v-container"} -->
<div class="wp-block-group v-container">
  <!-- wp:columns -->
  <div class="wp-block-columns">
    <!-- wp:column --><div class="wp-block-column"><div class="v-card"><h3>Aligned Agents</h3><p>Human-aligned orchestration with enterprise controls.</p></div></div><!-- /wp:column -->
    <!-- wp:column --><div class="wp-block-column"><div class="v-card"><h3>Neural Luxe UI</h3><p>Deep blues, electric purples, gold accents, premium motion.</p></div></div><!-- /wp:column -->
    <!-- wp:column --><div class="wp-block-column"><div class="v-card"><h3>Multi-Product Platform</h3><p>One core intelligence powering six flagship experiences.</p></div></div><!-- /wp:column -->
  </div>
  <!-- /wp:columns -->
</div>
<!-- /wp:group -->
PAT

cat <<'PAT' > "$PATTERNS/cta.php"
<!-- wp:group {"className":"v-container is-style-vireoka-panel"} -->
<div class="wp-block-group v-container is-style-vireoka-panel">
  <!-- wp:heading -->
  <h2>Enterprise Request Demo</h2>
  <!-- /wp:heading -->
  <!-- wp:paragraph -->
  <p>Talk to Vireoka about agents, security, integrations, and enterprise deployment.</p>
  <!-- /wp:paragraph -->
  <!-- wp:buttons -->
  <div class="wp-block-buttons">
    <!-- wp:button {"className":"is-style-vireoka-primary"} -->
    <div class="wp-block-button is-style-vireoka-primary"><a class="wp-block-button__link wp-element-button">Request Demo</a></div>
    <!-- /wp:button -->
  </div>
  <!-- /wp:buttons -->
</div>
<!-- /wp:group -->
PAT

# -------------------------------------------------
# 6) Figma parity: export tokens from CSS → JSON
# -------------------------------------------------
cat <<'PY' > "$TOKENS/export_tokens_json.py"
import json, re, pathlib

css_path = pathlib.Path(__file__).parent / "design-tokens.css"
text = css_path.read_text(encoding="utf-8")

# Capture --var: value; inside :root
root_block = re.search(r":root\\s*\\{([\\s\\S]*?)\\}", text)
vars_dict = {}
if root_block:
  for m in re.finditer(r"--([a-zA-Z0-9\\-]+)\\s*:\\s*([^;]+);", root_block.group(1)):
    vars_dict[m.group(1)] = m.group(2).strip()

out = {
  "name": "Vireoka Elite Neural Luxe Tokens",
  "source": "design-tokens.css",
  "tokens": vars_dict
}

out_path = pathlib.Path(__file__).parent / "design-tokens.figma.json"
out_path.write_text(json.dumps(out, indent=2), encoding="utf-8")
print(f"Wrote: {out_path}")
PY

cat <<'SH' > "$TOKENS/export_tokens_json.sh"
#!/usr/bin/env bash
set -e
python3 "$(dirname "$0")/export_tokens_json.py"
SH
chmod +x "$TOKENS/export_tokens_json.sh"

# -------------------------------------------------
# 7) Investor memo build kit (HTML + LaTeX + build helpers)
# -------------------------------------------------
cat <<'HTML' > "$PDF/investor-memo.html"
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Vireoka — Investor Memorandum</title>
<style>
:root{--bg:#0A1A4A;--gold:#E4B448;--muted:#C7CBD4;}
body{margin:0;padding:72px;font-family:Inter,system-ui,Segoe UI,Roboto,Arial,sans-serif;background:var(--bg);color:#fff;}
h1{color:var(--gold);font-weight:900;letter-spacing:-.02em;margin:0 0 12px;}
p{color:var(--muted);font-size:18px;line-height:1.6;max-width:80ch}
.section{margin-top:28px;padding:24px;border:1px solid rgba(255,255,255,.12);border-radius:18px;background:rgba(27,34,53,.55)}
</style>
</head>
<body>
<h1>Vireoka — Investor Memorandum</h1>
<p>Elite AI Agent Leadership + Multi-Product Platform. Deep-tech credibility with luxury-grade execution.</p>
<div class="section">
  <h2>Executive Summary</h2>
  <p>Vireoka is building a unified agent cloud powering six flagship products across intelligence, communication, community, creativity, finance, and cloud optimization.</p>
</div>
</body>
</html>
HTML

cat <<'TEX' > "$PDF/investor-memo.tex"
\\documentclass[11pt]{article}
\\usepackage[margin=1in]{geometry}
\\usepackage{xcolor}
\\definecolor{VireokaBlue}{RGB}{10,26,74}
\\definecolor{VireokaGold}{RGB}{228,180,72}
\\begin{document}
\\pagecolor{VireokaBlue}
\\color{white}
\\section*{\\textcolor{VireokaGold}{Vireoka — Investor Memorandum}}
Elite AI Agent Leadership + Multi-Product Platform.
\\end{document}
TEX

cat <<'SH' > "$PDF/build.sh"
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
echo "Build options:"
echo "  1) HTML (open investor-memo.html)"
echo "  2) LaTeX (pdflatex investor-memo.tex) if pdflatex exists"
if command -v pdflatex >/dev/null 2>&1; then
  pdflatex -interaction=nonstopmode investor-memo.tex >/dev/null
  echo "Built: investor-memo.pdf"
else
  echo "pdflatex not found (install texlive-full if you want PDF build)."
fi
SH
chmod +x "$PDF/build.sh"

echo "✅ Installed Elite Neural Luxe v2"
echo "Next:"
echo "  - Refresh http://localhost:8085"
echo "  - Run tokens export: $TOKENS/export_tokens_json.sh"
echo "  - Build memo: $PDF/build.sh"
