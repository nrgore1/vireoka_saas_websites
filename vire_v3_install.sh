#!/usr/bin/env bash
set -euo pipefail

echo "🧠 Installing Vire V3 — Agentic Website Generator"

ROOT="vire-agent"
V3="$ROOT/v3"

AGENT="$V3/agent"
PRESETS="$V3/presets"
OUTPUTS="$V3/outputs"

mkdir -p "$AGENT" "$PRESETS" "$OUTPUTS"

# =========================================================
# 1) Prompt → site.json Agent
# =========================================================
cat <<'PY' > "$AGENT/prompt_to_site.py"
#!/usr/bin/env python3
import json, sys, datetime

if len(sys.argv) < 3:
    print("Usage: prompt_to_site.py <preset.json> <product_name>")
    sys.exit(1)

preset = json.load(open(sys.argv[1]))
product_name = sys.argv[2]

site = {
    "site_id": product_name.lower().replace(" ", "-"),
    "product_name": product_name,
    "tone": preset.get("tone", "neural-luxe"),
    "audience": preset.get("audience"),
    "keywords": preset.get("keywords"),
    "pages": preset.get("pages"),
    "generated_at": datetime.datetime.utcnow().isoformat() + "Z"
}

out = "vire-agent/v3/outputs/site.json"
json.dump(site, open(out,"w"), indent=2)
print("✅ site.json generated:", out)
PY
chmod +x "$AGENT/prompt_to_site.py"

# =========================================================
# 2) Copy Engine (SEO-safe deterministic copy)
# =========================================================
cat <<'PY' > "$AGENT/copy_engine.py"
#!/usr/bin/env python3
import json, pathlib

site = json.load(open("vire-agent/v3/outputs/site.json"))

def page_copy(title):
    return f"""
<h1>{title}</h1>
<p><strong>{site['product_name']}</strong> is built for {site['audience']}.</p>
<p>Core focus: {', '.join(site['keywords'])}.</p>
"""

pages_dir = pathlib.Path("vire-agent/export/pages")
pages_dir.mkdir(parents=True, exist_ok=True)

for page in site["pages"]:
    slug = page.lower().replace(" ", "-")
    (pages_dir / f"{slug}.html").write_text(page_copy(page))

print("✅ Copy generated for pages")
PY
chmod +x "$AGENT/copy_engine.py"

# =========================================================
# 3) Schema Generator (E-E-A-T + Product)
# =========================================================
cat <<'PY' > "$AGENT/schema_engine.py"
#!/usr/bin/env python3
import json, pathlib

site = json.load(open("vire-agent/v3/outputs/site.json"))

schema = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": site["product_name"],
  "applicationCategory": "AIApplication",
  "keywords": site["keywords"],
  "author": {
    "@type": "Person",
    "name": "Narendra Gore"
  }
}

out = pathlib.Path("vire-agent/export/schema.json")
out.write_text(json.dumps(schema, indent=2))
print("✅ Schema generated:", out)
PY
chmod +x "$AGENT/schema_engine.py"

# =========================================================
# 4) Presets (1–6 products)
# =========================================================
cat <<'JSON' > "$PRESETS/atmasphere.json"
{
  "tone": "philosophical-ai",
  "audience": "researchers, seekers, AI philosophers",
  "keywords": ["AI agent frameworks", "Vedantic reasoning", "LLM alignment"],
  "pages": ["Home", "Research", "Alignment", "Contact"]
}
JSON

cat <<'JSON' > "$PRESETS/dating.json"
{
  "tone": "warm-inclusive",
  "audience": "founders building niche dating platforms",
  "keywords": ["niche dating platform creator", "AI matchmaking", "community AI"],
  "pages": ["Home", "Features", "Pricing", "Waitlist"]
}
JSON

cat <<'JSON' > "$PRESETS/stablecoin.json"
{
  "tone": "secure-futuristic",
  "audience": "fintech founders and investors",
  "keywords": ["quantum secure stablecoin", "onchain yield", "AI risk modeling"],
  "pages": ["Home", "Security", "Compliance", "Investors"]
}
JSON

# =========================================================
# 5) Vire V3 Runner
# =========================================================
cat <<'SH' > "$V3/vire_v3_run.sh"
#!/usr/bin/env bash
set -euo pipefail

PRESET="${1:?preset required}"
NAME="${2:?product name required}"

echo "🚀 Vire V3 generating site for: $NAME"

python3 vire-agent/v3/agent/prompt_to_site.py "$PRESET" "$NAME"
python3 vire-agent/v3/agent/copy_engine.py
python3 vire-agent/v3/agent/schema_engine.py

# Reuse V2 pipeline
python3 vire-agent/v2/theme/bodyclass_inject.py || true
python3 vire-agent/v2/dashboard/render_dashboard.py || true

echo "✅ Vire V3 complete"
echo "➡ Pages: vire-agent/export/pages"
echo "➡ Schema: vire-agent/export/schema.json"
SH
chmod +x "$V3/vire_v3_run.sh"

echo
echo "✅ Vire V3 installed"
echo "Run:"
echo "  ./vire-agent/v3/vire_v3_run.sh vire-agent/v3/presets/dating.json \"AI Dating Builder\""
