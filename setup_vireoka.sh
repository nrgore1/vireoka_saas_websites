#!/usr/bin/env bash
set -euo pipefail

# ============================================
# Vireoka Teaser Website (Phase 1) + Phase 2 shell
# Futuristic Minimalist w/ Gothic Geometry
# ============================================

ROOT_DIR="vireoka_web"

echo "🧱 Creating Vireoka teaser site at: $ROOT_DIR"
mkdir -p "$ROOT_DIR/css" "$ROOT_DIR/js" "$ROOT_DIR/assets"
mkdir -p "$ROOT_DIR/subdomains/dating" "$ROOT_DIR/subdomains/stablecoin" "$ROOT_DIR/subdomains/atmasphere"
mkdir -p "$ROOT_DIR/blog" "$ROOT_DIR/whitepapers"

# -----------------------------
# Global CSS (custom tokens + utilities)
# Tailwind is loaded via CDN in HTML for Phase 1 speed
# -----------------------------
cat <<'CSS' > "$ROOT_DIR/css/styles.css"
/* ==========================================================
   Vireoka Web — Phase 1 Tokens + Custom Utilities
   Palette: Slate-900 bg, Blue-500 accents, Zinc-200 text
   Style: Futuristic Minimalist + Gothic Geometry
   ========================================================== */

:root {
  --bg: #0b1220;              /* slate-like */
  --panel: rgba(255,255,255,.06);
  --panel2: rgba(255,255,255,.04);
  --border: rgba(255,255,255,.10);
  --text: #e4e4e7;            /* zinc-200 */
  --muted: rgba(228,228,231,.72);
  --accent: #3b82f6;          /* blue-500 */
  --accent2: #60a5fa;         /* blue-400 */
  --glow: rgba(59,130,246,.45);
  --danger: rgba(239,68,68,.75);
  --radius: 18px;
  --radius2: 24px;
  --shadow: 0 18px 60px rgba(0,0,0,.55);
  --shadowSoft: 0 10px 30px rgba(0,0,0,.35);
  --gridMax: 1120px;
  --mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
}

/* Base */
* { box-sizing: border-box; }
html, body { height: 100%; }
body {
  margin: 0;
  color: var(--text);
  background: radial-gradient(1200px 900px at 20% 10%, rgba(59,130,246,.18), transparent 50%),
              radial-gradient(900px 700px at 80% 0%, rgba(96,165,250,.14), transparent 55%),
              radial-gradient(900px 700px at 60% 90%, rgba(59,130,246,.10), transparent 55%),
              var(--bg);
  font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Apple Color Emoji","Segoe UI Emoji";
  overflow-x: hidden;
}

a { color: inherit; text-decoration: none; }
a:hover { text-decoration: underline; }
img { max-width: 100%; height: auto; }

/* Layout helpers */
.v-wrap { max-width: var(--gridMax); margin: 0 auto; padding: 0 20px; }
.v-topbar {
  position: sticky; top: 0; z-index: 50;
  background: rgba(11,18,32,.65);
  border-bottom: 1px solid rgba(255,255,255,.08);
  backdrop-filter: blur(10px);
}
.v-topbar-inner { display:flex; align-items:center; justify-content:space-between; padding: 14px 0; gap: 16px; }
.v-brand { display:flex; align-items:center; gap: 10px; letter-spacing: .2px; font-weight: 700; }
.v-brand svg { filter: drop-shadow(0 0 12px rgba(59,130,246,.35)); }
.v-nav { display:flex; align-items:center; gap: 14px; font-size: 14px; color: rgba(228,228,231,.86); }
.v-nav a { padding: 8px 10px; border-radius: 999px; }
.v-nav a:hover { background: rgba(255,255,255,.06); text-decoration: none; }

/* Gothic line-art / geometric overlays */
.gothic-line-art {
  position: absolute;
  inset: -120px -120px auto -120px;
  height: 520px;
  pointer-events: none;
  opacity: .35;
  mask-image: radial-gradient(circle at 30% 25%, rgba(0,0,0,1), rgba(0,0,0,0) 70%);
}
.gothic-line-art svg { width: 100%; height: 100%; }

/* Glass panel */
.glass-panel {
  background: linear-gradient(180deg, rgba(255,255,255,.07), rgba(255,255,255,.04));
  border: 1px solid rgba(255,255,255,.10);
  border-radius: var(--radius2);
  box-shadow: var(--shadowSoft);
  backdrop-filter: blur(14px);
}

/* CTA pulse */
.pulsing-cta {
  position: relative;
  border-radius: 999px;
  box-shadow: 0 0 0 rgba(59,130,246,0);
  animation: pulseGlow 2.4s ease-in-out infinite;
}
@keyframes pulseGlow {
  0%   { box-shadow: 0 0 0 0 rgba(59,130,246,.35); transform: translateY(0); }
  50%  { box-shadow: 0 0 0 14px rgba(59,130,246,0); transform: translateY(-1px); }
  100% { box-shadow: 0 0 0 0 rgba(59,130,246,0); transform: translateY(0); }
}

/* Animated divider */
.v-divider {
  width: 100%;
  height: 44px;
  opacity: .85;
  overflow: hidden;
  filter: drop-shadow(0 0 12px rgba(59,130,246,.18));
}
.v-divider svg { width: 120%; height: 100%; transform: translateX(-5%); }
.v-divider path {
  stroke: rgba(255,255,255,.18);
  stroke-width: 1;
  fill: none;
  stroke-dasharray: 6 8;
  animation: dash 14s linear infinite;
}
@keyframes dash { to { stroke-dashoffset: -300; } }

/* Hero */
.v-hero { position: relative; padding: 64px 0 36px; }
.v-hero h1 { font-size: clamp(34px, 4.4vw, 56px); line-height: 1.05; margin: 0 0 14px; letter-spacing: -0.02em; }
.v-hero p { max-width: 70ch; margin: 0 0 22px; color: var(--muted); font-size: 16px; line-height: 1.65; }
.v-hero .v-cta-row { display:flex; gap: 12px; flex-wrap: wrap; align-items:center; }
.v-badge {
  display:inline-flex; align-items:center; gap: 8px;
  padding: 8px 12px;
  border-radius: 999px;
  border: 1px solid rgba(255,255,255,.10);
  background: rgba(255,255,255,.05);
  font-size: 12px;
  color: rgba(228,228,231,.88);
}

/* Bento grid */
.v-grid { display:grid; grid-template-columns: repeat(12, 1fr); gap: 14px; margin: 22px 0 0; }
.v-card {
  position: relative;
  padding: 18px 18px 16px;
  border-radius: var(--radius2);
  background: linear-gradient(180deg, rgba(255,255,255,.06), rgba(255,255,255,.03));
  border: 1px solid rgba(255,255,255,.10);
  box-shadow: var(--shadowSoft);
  transition: transform .18s ease, border-color .18s ease, box-shadow .18s ease;
  overflow: hidden;
}
.v-card:hover { transform: translateY(-2px); border-color: rgba(96,165,250,.35); box-shadow: 0 14px 50px rgba(0,0,0,.55); }
.v-card h3 { margin: 0 0 8px; font-size: 16px; }
.v-card p { margin: 0; color: var(--muted); font-size: 13px; line-height: 1.55; }
.v-chip {
  position:absolute; top: 14px; right: 14px;
  font-size: 11px; padding: 6px 10px; border-radius: 999px;
  border: 1px solid rgba(255,255,255,.10);
  background: rgba(255,255,255,.04);
}
.v-chip.beta { border-color: rgba(59,130,246,.35); background: rgba(59,130,246,.10); }
.v-chip.soon { border-color: rgba(255,255,255,.12); background: rgba(255,255,255,.05); }

/* Footer */
footer { padding: 34px 0; margin-top: 52px; border-top: 1px solid rgba(255,255,255,.08); color: rgba(228,228,231,.70); font-size: 13px; }
footer a { color: rgba(228,228,231,.85); }

/* Forms */
.v-form { display:flex; gap: 10px; flex-wrap: wrap; }
.v-input {
  min-width: 260px;
  flex: 1;
  border-radius: 999px;
  border: 1px solid rgba(255,255,255,.10);
  background: rgba(255,255,255,.05);
  padding: 12px 14px;
  color: var(--text);
  outline: none;
}
.v-input:focus { border-color: rgba(96,165,250,.55); box-shadow: 0 0 0 4px rgba(59,130,246,.15); }

.v-btn {
  border: 0;
  border-radius: 999px;
  padding: 12px 16px;
  background: linear-gradient(135deg, rgba(59,130,246,1), rgba(96,165,250,1));
  color: #06101f;
  font-weight: 700;
  cursor: pointer;
  transition: transform .15s ease, filter .15s ease;
}
.v-btn:hover { transform: translateY(-1px); filter: brightness(1.05); }
.v-btn.secondary {
  background: rgba(255,255,255,.05);
  color: var(--text);
  border: 1px solid rgba(255,255,255,.12);
}

/* Small print */
.v-legal { color: rgba(228,228,231,.62); font-size: 12px; line-height: 1.55; }

/* Responsive */
@media (max-width: 820px) {
  .v-nav { display:none; }
  .v-grid { grid-template-columns: 1fr; }
}
CSS

# -----------------------------
# Global JS (lightweight)
# -----------------------------
cat <<'JS' > "$ROOT_DIR/js/app.js"
(function () {
  // Smooth anchor scroll
  document.addEventListener('click', function (e) {
    const a = e.target.closest('a[href^="#"]');
    if (!a) return;
    const id = a.getAttribute('href').slice(1);
    const el = document.getElementById(id);
    if (!el) return;
    e.preventDefault();
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });

  // Add a tiny "loaded" class for subtle transitions if needed
  window.addEventListener('load', function () {
    document.documentElement.classList.add('v-loaded');
  });
})();
JS

# -----------------------------
# Minimal line-art SVG asset
# -----------------------------
cat <<'SVG' > "$ROOT_DIR/assets/gothic-grid.svg"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 520">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="rgba(59,130,246,.55)"/>
      <stop offset="1" stop-color="rgba(255,255,255,.12)"/>
    </linearGradient>
  </defs>
  <g fill="none" stroke="url(#g)" stroke-width="1" opacity="0.85">
    <path d="M40,60 L1160,60" />
    <path d="M40,120 L1160,120" />
    <path d="M40,180 L1160,180" />
    <path d="M40,240 L1160,240" />
    <path d="M40,300 L1160,300" />
    <path d="M40,360 L1160,360" />
    <path d="M40,420 L1160,420" />

    <path d="M120,40 L120,480" />
    <path d="M260,40 L260,480" />
    <path d="M400,40 L400,480" />
    <path d="M540,40 L540,480" />
    <path d="M680,40 L680,480" />
    <path d="M820,40 L820,480" />
    <path d="M960,40 L960,480" />
    <path d="M1100,40 L1100,480" />

    <path d="M120,120 L260,60 L400,120 L540,60 L680,120 L820,60 L960,120 L1100,60" opacity="0.55"/>
    <path d="M120,420 L260,480 L400,420 L540,480 L680,420 L820,480 L960,420 L1100,480" opacity="0.55"/>

    <circle cx="260" cy="180" r="6" />
    <circle cx="540" cy="240" r="6" />
    <circle cx="820" cy="300" r="6" />
  </g>
</svg>
SVG

# -----------------------------
# Shared JSON-LD (Organization + Products)
# -----------------------------
cat <<'JSON' > "$ROOT_DIR/assets/schema.json"
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "name": "Vireoka LLC",
      "url": "https://vireoka.com",
      "logo": "https://vireoka.com/wp-content/uploads/logo.png",
      "description": "Vireoka builds AI-agent ecosystems across communication, creativity, cloud, finance, and human connection.",
      "sameAs": [
        "https://www.linkedin.com/company/vireoka"
      ]
    },
    {
      "@type": "SoftwareApplication",
      "name": "AtmaSphere LLM",
      "applicationCategory": "BusinessApplication",
      "operatingSystem": "Web",
      "description": "An aligned intelligence engine for multi-agent reasoning and safe outcome orchestration."
    },
    {
      "@type": "SoftwareApplication",
      "name": "Business Comm Training",
      "applicationCategory": "EducationalApplication",
      "operatingSystem": "Web",
      "description": "Communication and debate coaching with AI agents for viral clarity and persuasion."
    },
    {
      "@type": "SoftwareApplication",
      "name": "Niche Dating Platform Creator",
      "applicationCategory": "SocialNetworkingApplication",
      "operatingSystem": "Web",
      "description": "A niche dating platform creator that generates invitation-first communities and matchmaking systems."
    },
    {
      "@type": "SoftwareApplication",
      "name": "Memoir Creation Platform",
      "applicationCategory": "MultimediaApplication",
      "operatingSystem": "Web",
      "description": "A memoir creation platform that turns life stories into print-ready coffee-table books."
    },
    {
      "@type": "SoftwareApplication",
      "name": "Cloud Infrastructure Cost Reducer",
      "applicationCategory": "BusinessApplication",
      "operatingSystem": "Web",
      "description": "Autonomous FinOps intelligence for continuous cloud cost reduction and GPU/CPU optimization."
    },
    {
      "@type": "SoftwareApplication",
      "name": "Quantum-Secure Stablecoin",
      "applicationCategory": "FinanceApplication",
      "operatingSystem": "Web",
      "description": "A quantum secure stablecoin concept for future-proof, compliant digital finance."
    }
  ]
}
JSON

# -----------------------------
# index.html (Umbrella Teaser)
# -----------------------------
cat <<'HTML' > "$ROOT_DIR/index.html"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Vireoka AI Ecosystem | Quantum Stablecoins & Niche Agents</title>
  <meta name="description" content="Vireoka builds AI agent frameworks across six products. Explore greenfield AI opportunities, a quantum secure stablecoin vision, and a niche dating platform creator—designed for high-trust outcomes." />
  <meta name="robots" content="index,follow" />

  <!-- OpenGraph -->
  <meta property="og:title" content="Vireoka — De-risking Innovation through Agentic AI" />
  <meta property="og:description" content="Six products. One agent cloud. AI agent frameworks for communication, dating, memoir, cloud cost reduction, and quantum secure stablecoin finance." />
  <meta property="og:type" content="website" />
  <meta property="og:url" content="https://vireoka.com" />
  <meta property="og:image" content="assets/og-placeholder.png" />

  <!-- Tailwind (Phase 1 speed via CDN) -->
  <script src="https://cdn.tailwindcss.com"></script>

  <!-- Custom CSS -->
  <link rel="stylesheet" href="css/styles.css" />

  <!-- JSON-LD Schema -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        "name": "Vireoka LLC",
        "url": "https://vireoka.com",
        "description": "Vireoka builds AI-agent ecosystems across communication, creativity, cloud, finance, and human connection."
      }
    ]
  }
  </script>

  <!-- Inline critical CSS (tiny) -->
  <style>
    .v-hide { display:none; }
  </style>
</head>

<body>
  <div class="v-topbar">
    <div class="v-wrap v-topbar-inner">
      <a class="v-brand" href="index.html" aria-label="Vireoka Home">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2Z" stroke="rgba(255,255,255,.65)"/>
          <path d="M7 12c2.2-3.6 7.8-3.6 10 0" stroke="rgba(59,130,246,.9)"/>
          <path d="M7 12c2.2 3.6 7.8 3.6 10 0" stroke="rgba(96,165,250,.55)"/>
        </svg>
        <span>Vireoka</span>
      </a>

      <nav class="v-nav" aria-label="Primary navigation">
        <a href="#ecosystem">Ecosystem</a>
        <a href="#founder">Founder’s Note</a>
        <a href="#waitlist">Waitlist</a>
        <a href="blog/index.html">Blog</a>
        <a href="whitepapers/index.html">Whitepapers</a>
      </nav>

      <a class="v-btn pulsing-cta" href="#waitlist">Subscribe</a>
    </div>
  </div>

  <header class="v-hero v-wrap">
    <div class="gothic-line-art" aria-hidden="true">
      <img src="assets/gothic-grid.svg" alt="" loading="lazy" />
    </div>

    <span class="v-badge">
      <span style="width:8px;height:8px;border-radius:999px;background:rgba(59,130,246,.9);display:inline-block;"></span>
      Futuristic Minimalist • Gothic Geometry • High-performance
    </span>

    <h1 class="mt-4">
      Vireoka: De-risking Innovation through Agentic AI
    </h1>

    <p>
      We build <strong>AI agent frameworks</strong> that help teams ship outcomes: safer decisions, clearer communication,
      and measurable performance. Our ecosystem targets <strong>greenfield AI opportunities</strong> across six products—
      including a <strong>quantum secure stablecoin</strong> thesis and a <strong>niche dating platform creator</strong>.
    </p>

    <div class="v-cta-row">
      <a class="v-btn pulsing-cta" href="#ecosystem">Explore the Ecosystem</a>
      <a class="v-btn secondary" href="#waitlist">Investor / Early Access</a>
    </div>

    <div class="v-divider mt-8" aria-hidden="true">
      <svg viewBox="0 0 1200 44" xmlns="http://www.w3.org/2000/svg">
        <path d="M0,22 C200,6 400,38 600,22 C800,6 1000,38 1200,22" />
      </svg>
    </div>
  </header>

  <main class="v-wrap">
    <section id="ecosystem" class="mt-10">
      <h2 class="text-2xl font-semibold tracking-tight">The Vireoka Ecosystem</h2>
      <p class="mt-2" style="color: var(--muted); max-width: 78ch;">
        Six products. One coherent platform vision. Priority/Beta indicates faster activation and near-term launches.
      </p>

      <div class="v-grid">
        <!-- 1: AtmaSphere (Priority/Beta) -->
        <a class="v-card glass-panel" style="grid-column: span 7;" href="subdomains/atmasphere/index.html">
          <span class="v-chip beta">Priority / Beta</span>
          <h3>1) AtmaSphere LLM</h3>
          <p>Aligned intelligence engine for multi-agent reasoning, cultural nuance, and outcome orchestration.</p>
        </a>

        <!-- 6: Stablecoin (Priority/Beta) -->
        <a class="v-card glass-panel" style="grid-column: span 5;" href="subdomains/stablecoin/index.html">
          <span class="v-chip beta">Priority / Beta</span>
          <h3>6) Quantum-Secure Stablecoin</h3>
          <p>Future-proof finance thesis with YMYL-aware compliance posture and security-first architecture.</p>
        </a>

        <!-- 3: Dating (Priority/Beta) -->
        <a class="v-card glass-panel" style="grid-column: span 6;" href="subdomains/dating/index.html">
          <span class="v-chip beta">Priority / Beta</span>
          <h3>3) Niche Dating Platform Creator</h3>
          <p>A niche dating platform creator that spins up invitation-first communities (e.g., Indian diaspora, sports lovers).</p>
        </a>

        <!-- 2: Business Comm (Coming Soon) -->
        <div class="v-card" style="grid-column: span 6;">
          <span class="v-chip soon">Coming Soon</span>
          <h3>2) Business Comm Training</h3>
          <p>AI-driven coaching for persuasion, debate, and virality—structured feedback loops, practice drills, and confidence.</p>
        </div>

        <!-- 4: Memoir (Coming Soon) -->
        <div class="v-card" style="grid-column: span 5;">
          <span class="v-chip soon">Coming Soon</span>
          <h3>4) Memoir Creation Platform</h3>
          <p>Turn life stories into print-ready coffee-table books with guided layouts, AI rewrite, and asset management.</p>
        </div>

        <!-- 5: Cloud Cost Reducer (Coming Soon) -->
        <div class="v-card" style="grid-column: span 7;">
          <span class="v-chip soon">Coming Soon</span>
          <h3>5) Cloud Infrastructure Cost Reducer</h3>
          <p>Autonomous FinOps intelligence for continuous savings, GPU utilization, and infrastructure drift detection.</p>
        </div>
      </div>
    </section>

    <section id="founder" class="mt-12 glass-panel" style="padding: 22px;">
      <h2 class="text-2xl font-semibold tracking-tight">Founder’s Note (E-E-A-T)</h2>
      <p class="mt-2" style="color: var(--muted); max-width: 82ch;">
        I’m building Vireoka with a simple obsession: reduce risk while increasing the speed of innovation.
        I’ve spent years designing multi-service systems, AI workflows, and secure deployment pipelines—
        and I’ve learned that the hardest part isn’t models. It’s <em>trust</em>: reliability, safety, governance, and measurable outcomes.
      </p>
      <p class="mt-3 v-legal" style="max-width: 92ch;">
        This teaser site is intentionally non-technical. The launch version will include audited claims, benchmarks where appropriate,
        and clear decision-rights for agent systems—especially for finance and other YMYL-adjacent areas.
      </p>
    </section>

    <section id="waitlist" class="mt-12 glass-panel" style="padding: 22px;">
      <h2 class="text-2xl font-semibold tracking-tight">Investor / Early Access Waitlist</h2>
      <p class="mt-2" style="color: var(--muted); max-width: 80ch;">
        If you’re an investor, enterprise leader, or early adopter exploring <strong>greenfield AI opportunities</strong>,
        join the list. We’ll share private launch updates and early demos (when available).
      </p>

      <!-- Netlify Forms compatible -->
      <form class="v-form mt-4" name="vireoka-waitlist" method="POST" data-netlify="true">
        <input type="hidden" name="form-name" value="vireoka-waitlist" />
        <label class="v-hide">
          Don’t fill this out if you're human: <input name="bot-field" />
        </label>
        <input class="v-input" type="email" name="email" placeholder="Email address" required />
        <button class="v-btn pulsing-cta" type="submit">Join Waitlist</button>
        <a class="v-btn secondary" href="whitepapers/index.html">Quantum Security Brief</a>
      </form>

      <p class="mt-3 v-legal">
        No spam. We only email when there’s something meaningful (launch, demo, or roadmap update).
      </p>
    </section>

    <footer class="v-wrap">
      <div style="display:flex; flex-wrap: wrap; gap: 14px; justify-content: space-between; align-items: center;">
        <div>© <span id="y"></span> Vireoka LLC</div>
        <div style="display:flex; gap: 14px; flex-wrap: wrap;">
          <a href="subdomains/stablecoin/index.html">Stablecoin</a>
          <a href="subdomains/dating/index.html">Dating</a>
          <a href="subdomains/atmasphere/index.html">AtmaSphere</a>
          <a href="blog/index.html">Blog</a>
          <a href="whitepapers/index.html">Whitepapers</a>
        </div>
      </div>
      <script>document.getElementById('y').textContent = new Date().getFullYear();</script>
    </footer>
  </main>

  <script src="js/app.js" defer></script>
</body>
</html>
HTML

# -----------------------------
# subdomains/dating/index.html
# -----------------------------
cat <<'HTML' > "$ROOT_DIR/subdomains/dating/index.html"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Niche Dating Platform Creator | Vireoka</title>
  <meta name="description" content="A niche dating platform creator that helps communities connect authentically. Invitation-first, privacy-aware, and AI-assisted—built for real relationships." />
  <meta name="robots" content="index,follow" />

  <meta property="og:title" content="Niche Dating Platform Creator — Vireoka" />
  <meta property="og:description" content="Connect authentically with AI magic. Invitation-first communities and one-click site creation." />
  <meta property="og:type" content="website" />

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="../../css/styles.css" />

  <script type="application/ld+json">
  {
    "@context":"https://schema.org",
    "@type":"SoftwareApplication",
    "name":"Niche Dating Platform Creator",
    "applicationCategory":"SocialNetworkingApplication",
    "operatingSystem":"Web",
    "description":"A niche dating platform creator for invitation-first communities with privacy and trust controls."
  }
  </script>
</head>

<body>
  <div class="v-topbar">
    <div class="v-wrap v-topbar-inner">
      <a class="v-brand" href="../../index.html"><span>← Vireoka</span></a>
      <a class="v-btn pulsing-cta" href="#waitlist">Join Waitlist</a>
    </div>
  </div>

  <header class="v-hero v-wrap">
    <div class="gothic-line-art" aria-hidden="true">
      <img src="../../assets/gothic-grid.svg" alt="" loading="lazy" />
    </div>

    <span class="v-badge">Priority / Beta</span>
    <h1 class="mt-4">Connect Authentically with AI Magic</h1>
    <p>
      Vireoka’s <strong>niche dating platform creator</strong> helps founders and community leaders launch
      invitation-first dating experiences—tailored to specific groups (Indian diaspora, sports lovers, faith communities, alumni networks).
    </p>

    <div class="v-divider mt-8" aria-hidden="true">
      <svg viewBox="0 0 1200 44" xmlns="http://www.w3.org/2000/svg">
        <path d="M0,22 C200,6 400,38 600,22 C800,6 1000,38 1200,22" />
      </svg>
    </div>
  </header>

  <main class="v-wrap">
    <section class="glass-panel" style="padding: 22px;">
      <h2 class="text-2xl font-semibold tracking-tight">What you can launch</h2>
      <ul class="mt-3" style="color: var(--muted); line-height: 1.8;">
        <li>• Invitation-only onboarding with trust & verification flows</li>
        <li>• AI-assisted profile creation and compatibility insights</li>
        <li>• Privacy controls, visibility modes, and safety-first chat patterns</li>
        <li>• One-click “site creation” workflows (placeholder demo below)</li>
      </ul>

      <div class="mt-6 v-card glass-panel" style="padding: 16px;">
        <h3>Video Placeholder: “One-click site creation”</h3>
        <p class="mt-2" style="color: var(--muted);">
          Swap this with a short product demo or animated walkthrough.
        </p>
        <div class="mt-4" style="border: 1px dashed rgba(255,255,255,.18); border-radius: 14px; height: 220px; display:flex; align-items:center; justify-content:center; color: rgba(228,228,231,.55);">
          Demo video goes here
        </div>
      </div>
    </section>

    <section id="waitlist" class="mt-10 glass-panel" style="padding: 22px;">
      <h2 class="text-2xl font-semibold tracking-tight">Join the Waitlist</h2>
      <p class="mt-2" style="color: var(--muted);">
        Want to launch a niche community? Get early access updates.
      </p>

      <form class="v-form mt-4" name="dating-waitlist" method="POST" data-netlify="true">
        <input type="hidden" name="form-name" value="dating-waitlist" />
        <input class="v-input" type="email" name="email" placeholder="Email address" required />
        <button class="v-btn pulsing-cta" type="submit">Join Waitlist</button>
        <a class="v-btn secondary" href="../../index.html#ecosystem">Back to Ecosystem</a>
      </form>
    </section>

    <footer class="v-wrap">
      <div class="v-legal">
        © <span id="y"></span> Vireoka LLC • This is a teaser page. Details may change as we validate safety and trust requirements.
      </div>
      <script>document.getElementById('y').textContent = new Date().getFullYear();</script>
    </footer>
  </main>

  <script src="../../js/app.js" defer></script>
</body>
</html>
HTML

# -----------------------------
# subdomains/stablecoin/index.html
# -----------------------------
cat <<'HTML' > "$ROOT_DIR/subdomains/stablecoin/index.html"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Quantum-Proof Finance | Quantum Secure Stablecoin | Vireoka</title>
  <meta name="description" content="A quantum secure stablecoin thesis for future-proof finance. Security-first posture, compliance-aware design, and risk-managed innovation." />
  <meta name="robots" content="index,follow" />

  <meta property="og:title" content="Quantum-Proof Finance — Vireoka" />
  <meta property="og:description" content="A quantum secure stablecoin vision designed with security and compliance in mind (YMYL-aware)." />
  <meta property="og:type" content="website" />

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="../../css/styles.css" />

  <script type="application/ld+json">
  {
    "@context":"https://schema.org",
    "@type":"SoftwareApplication",
    "name":"Quantum-Secure Stablecoin",
    "applicationCategory":"FinanceApplication",
    "operatingSystem":"Web",
    "description":"A quantum secure stablecoin thesis for future-proof, compliance-aware digital finance."
  }
  </script>
</head>

<body>
  <div class="v-topbar">
    <div class="v-wrap v-topbar-inner">
      <a class="v-brand" href="../../index.html"><span>← Vireoka</span></a>
      <a class="v-btn pulsing-cta" href="#waitlist">Join Waitlist</a>
    </div>
  </div>

  <header class="v-hero v-wrap">
    <div class="gothic-line-art" aria-hidden="true">
      <img src="../../assets/gothic-grid.svg" alt="" loading="lazy" />
    </div>

    <span class="v-badge">Priority / Beta • YMYL-aware</span>
    <h1 class="mt-4">Quantum-Proof Finance</h1>
    <p>
      Vireoka’s <strong>quantum secure stablecoin</strong> concept focuses on safety, governance, and compliance posture—
      designed to de-risk financial innovation while building credibility.
    </p>

    <div class="v-divider mt-8" aria-hidden="true">
      <svg viewBox="0 0 1200 44" xmlns="http://www.w3.org/2000/svg">
        <path d="M0,22 C200,6 400,38 600,22 C800,6 1000,38 1200,22" />
      </svg>
    </div>
  </header>

  <main class="v-wrap">
    <section class="glass-panel" style="padding: 22px;">
      <h2 class="text-2xl font-semibold tracking-tight">Principles (Teaser)</h2>
      <ul class="mt-3" style="color: var(--muted); line-height: 1.8;">
        <li>• Security-first: threat modeling + audit mindset</li>
        <li>• Compliance-aware: clear claims, careful positioning</li>
        <li>• Risk-managed rollout: staged adoption</li>
        <li>• Designed for trust: transparent disclosures</li>
      </ul>

      <div class="mt-6 v-card glass-panel" style="padding: 16px;">
        <h3>Founder's Note (E-E-A-T)</h3>
        <p class="mt-2" style="color: var(--muted);">
          In finance, trust is the product. This teaser page intentionally avoids implementation claims.
          The launch site will include vetted language, risk disclosures, and a clear compliance stance.
        </p>
      </div>

      <div class="mt-5 v-card" style="border-left: 3px solid rgba(239,68,68,.65);">
        <h3 style="margin-top: 0;">Important Disclaimer (YMYL)</h3>
        <p class="v-legal mt-2">
          This page is for informational purposes only and does not constitute financial advice, investment advice,
          or an offer to buy/sell any asset. Any future product details will be subject to legal review and jurisdictional compliance.
        </p>
      </div>
    </section>

    <section id="waitlist" class="mt-10 glass-panel" style="padding: 22px;">
      <h2 class="text-2xl font-semibold tracking-tight">Join the Waitlist</h2>
      <p class="mt-2" style="color: var(--muted);">
        For investors and early partners exploring secure digital finance.
      </p>

      <form class="v-form mt-4" name="stablecoin-waitlist" method="POST" data-netlify="true">
        <input type="hidden" name="form-name" value="stablecoin-waitlist" />
        <input class="v-input" type="email" name="email" placeholder="Email address" required />
        <button class="v-btn pulsing-cta" type="submit">Join Waitlist</button>
        <a class="v-btn secondary" href="../../whitepapers/index.html">Quantum Security Brief</a>
      </form>
    </section>

    <footer class="v-wrap">
      <div class="v-legal">
        © <span id="y"></span> Vireoka LLC • YMYL disclaimer applies • Teaser content only
      </div>
      <script>document.getElementById('y').textContent = new Date().getFullYear();</script>
    </footer>
  </main>

  <script src="../../js/app.js" defer></script>
</body>
</html>
HTML

# -----------------------------
# subdomains/atmasphere/index.html
# -----------------------------
cat <<'HTML' > "$ROOT_DIR/subdomains/atmasphere/index.html"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>AtmaSphere LLM | AI Agent Frameworks for Trust | Vireoka</title>
  <meta name="description" content="AtmaSphere is Vireoka’s flagship intelligence engine for AI agent frameworks: multi-agent reasoning, aligned outcomes, and high-trust responses." />
  <meta name="robots" content="index,follow" />

  <meta property="og:title" content="AtmaSphere LLM — The Intelligence Behind Everything" />
  <meta property="og:description" content="Aligned intelligence for multi-agent reasoning and safe outcome orchestration." />
  <meta property="og:type" content="website" />

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="../../css/styles.css" />

  <script type="application/ld+json">
  {
    "@context":"https://schema.org",
    "@type":"SoftwareApplication",
    "name":"AtmaSphere LLM",
    "applicationCategory":"BusinessApplication",
    "operatingSystem":"Web",
    "description":"Aligned intelligence engine for multi-agent reasoning, trust, and outcome orchestration."
  }
  </script>
</head>

<body>
  <div class="v-topbar">
    <div class="v-wrap v-topbar-inner">
      <a class="v-brand" href="../../index.html"><span>← Vireoka</span></a>
      <a class="v-btn pulsing-cta" href="#waitlist">Request Early Access</a>
    </div>
  </div>

  <header class="v-hero v-wrap">
    <div class="gothic-line-art" aria-hidden="true">
      <img src="../../assets/gothic-grid.svg" alt="" loading="lazy" />
    </div>

    <span class="v-badge">Priority / Beta</span>
    <h1 class="mt-4">AtmaSphere LLM — The Intelligence Behind Everything</h1>
    <p>
      AtmaSphere powers Vireoka’s ecosystem with <strong>AI agent frameworks</strong> designed for
      contextual understanding, multi-agent reasoning, and trust-first outcomes—without leaking proprietary details.
    </p>

    <div class="v-divider mt-8" aria-hidden="true">
      <svg viewBox="0 0 1200 44" xmlns="http://www.w3.org/2000/svg">
        <path d="M0,22 C200,6 400,38 600,22 C800,6 1000,38 1200,22" />
      </svg>
    </div>
  </header>

  <main class="v-wrap">
    <section class="glass-panel" style="padding: 22px;">
      <h2 class="text-2xl font-semibold tracking-tight">What it enables (Teaser)</h2>
      <ul class="mt-3" style="color: var(--muted); line-height: 1.8;">
        <li>• Multi-agent reasoning and coordinated decision workflows</li>
        <li>• High-trust outputs with reduced hallucination risk posture</li>
        <li>• Human-aligned interaction layers and governance readiness</li>
        <li>• Cross-domain intelligence for platforms (not single tools)</li>
      </ul>

      <div class="mt-6 v-card glass-panel" style="padding: 16px;">
        <h3>Founder’s Note (E-E-A-T)</h3>
        <p class="mt-2" style="color: var(--muted);">
          The goal isn’t “smart answers.” It’s responsible outcomes. AtmaSphere is designed to support
          decision rights, traceability, and alignment—because agent systems should not drift without governance.
        </p>
      </div>
    </section>

    <section id="waitlist" class="mt-10 glass-panel" style="padding: 22px;">
      <h2 class="text-2xl font-semibold tracking-tight">Request Early Access</h2>
      <p class="mt-2" style="color: var(--muted);">
        Join for private updates on early demos and launch milestones.
      </p>

      <form class="v-form mt-4" name="atmasphere-waitlist" method="POST" data-netlify="true">
        <input type="hidden" name="form-name" value="atmasphere-waitlist" />
        <input class="v-input" type="email" name="email" placeholder="Email address" required />
        <button class="v-btn pulsing-cta" type="submit">Request Access</button>
        <a class="v-btn secondary" href="../../index.html#ecosystem">Back to Ecosystem</a>
      </form>
    </section>

    <footer class="v-wrap">
      <div class="v-legal">
        © <span id="y"></span> Vireoka LLC • Teaser content only • No proprietary implementation details disclosed
      </div>
      <script>document.getElementById('y').textContent = new Date().getFullYear();</script>
    </footer>
  </main>

  <script src="../../js/app.js" defer></script>
</body>
</html>
HTML

# -----------------------------
# Phase 2 placeholder: blog/index.html
# -----------------------------
cat <<'HTML' > "$ROOT_DIR/blog/index.html"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Blog | Vireoka</title>
  <meta name="description" content="Founder’s Journey and research notes on AI agent frameworks, governance, and product building." />
  <meta name="robots" content="index,follow" />

  <meta property="og:title" content="Vireoka Blog" />
  <meta property="og:description" content="Founder’s Journey, product notes, and platform thinking." />
  <meta property="og:type" content="website" />

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="../css/styles.css" />
</head>

<body>
  <div class="v-topbar">
    <div class="v-wrap v-topbar-inner">
      <a class="v-brand" href="../index.html"><span>← Vireoka</span></a>
      <a class="v-btn pulsing-cta" href="../index.html#waitlist">Subscribe</a>
    </div>
  </div>

  <main class="v-wrap" style="padding: 42px 0;">
    <section class="glass-panel" style="padding: 22px;">
      <h1 class="text-3xl font-semibold tracking-tight">Founder’s Journey (E-E-A-T)</h1>
      <p class="mt-2" style="color: var(--muted); max-width: 82ch;">
        This section is the Phase 2 foundation. Launch site will include signed posts, references, and
        experience-backed learnings to strengthen E-E-A-T for AI/YMYL-adjacent topics.
      </p>

      <article class="mt-6 v-card glass-panel" style="padding: 16px;">
        <h2 class="text-xl font-semibold tracking-tight">Why AI Agent Frameworks Need Decision Rights</h2>
        <p class="mt-2" style="color: var(--muted);">
          Placeholder article. Will cover governance, accountability, auditability, and the difference between automation and outcomes.
        </p>
        <p class="mt-3 v-legal">Status: Phase 2 placeholder • Coming soon</p>
      </article>
    </section>

    <footer class="v-wrap">
      <div class="v-legal">
        © <span id="y"></span> Vireoka LLC
      </div>
      <script>document.getElementById('y').textContent = new Date().getFullYear();</script>
    </footer>
  </main>

  <script src="../js/app.js" defer></script>
</body>
</html>
HTML

# -----------------------------
# Phase 2 placeholder: whitepapers/index.html
# -----------------------------
cat <<'HTML' > "$ROOT_DIR/whitepapers/index.html"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Whitepapers | Vireoka</title>
  <meta name="description" content="Quantum Security and agent governance notes. Lead-gen gate for early access." />
  <meta name="robots" content="index,follow" />

  <meta property="og:title" content="Vireoka Whitepapers" />
  <meta property="og:description" content="Research notes and early briefs. Request access to downloads." />
  <meta property="og:type" content="website" />

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="../css/styles.css" />
</head>

<body>
  <div class="v-topbar">
    <div class="v-wrap v-topbar-inner">
      <a class="v-brand" href="../index.html"><span>← Vireoka</span></a>
      <a class="v-btn pulsing-cta" href="#gate">Request Download</a>
    </div>
  </div>

  <main class="v-wrap" style="padding: 42px 0;">
    <section class="glass-panel" style="padding: 22px;">
      <h1 class="text-3xl font-semibold tracking-tight">Quantum Security (Lead Gen)</h1>
      <p class="mt-2" style="color: var(--muted); max-width: 82ch;">
        Phase 2 foundation: downloadable brief gate for early partners and investors.
        The launch version can serve real PDFs (LaTeX/HTML exports) with analytics + consent.
      </p>

      <div class="mt-6 v-card glass-panel" style="padding: 16px;">
        <h2 class="text-xl font-semibold tracking-tight">Download Gate (Placeholder)</h2>
        <p class="mt-2" style="color: var(--muted);">
          Enter your email to request the Quantum Security brief. (Netlify Forms compatible)
        </p>

        <form id="gate" class="v-form mt-4" name="whitepaper-gate" method="POST" data-netlify="true">
          <input type="hidden" name="form-name" value="whitepaper-gate" />
          <input class="v-input" type="email" name="email" placeholder="Email address" required />
          <button class="v-btn pulsing-cta" type="submit">Request Download</button>
          <a class="v-btn secondary" href="../index.html#waitlist">Join Main Waitlist</a>
        </form>

        <p class="mt-3 v-legal">
          Note: This is a placeholder. The Phase 2 launch site will serve a real PDF with explicit disclaimers and references.
        </p>
      </div>
    </section>

    <footer class="v-wrap">
      <div class="v-legal">
        © <span id="y"></span> Vireoka LLC
      </div>
      <script>document.getElementById('y').textContent = new Date().getFullYear();</script>
    </footer>
  </main>

  <script src="../js/app.js" defer></script>
</body>
</html>
HTML

# -----------------------------
# Optional: OG placeholder image file (text stub)
# -----------------------------
cat <<'TXT' > "$ROOT_DIR/assets/og-placeholder.png"
PNG PLACEHOLDER
Replace with a real OG image later.
TXT

# -----------------------------
# Done
# -----------------------------
echo
echo "✅ Vireoka teaser site generated in: $ROOT_DIR/"
echo
echo "▶ Next steps (local preview):"
echo "  cd $ROOT_DIR"
echo "  python3 -m http.server 5173"
echo "  Open: http://localhost:5173/"
echo
echo "Tip: You can also use:"
echo "  npx serve ."
