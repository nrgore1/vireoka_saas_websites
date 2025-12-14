#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Installing Vire V4 (Pricing + SaaS Launcher + AtmaSphere Copy + WP Provisioning)"
echo "Run from: /mnt/c/Projects2025/vireoka_website"
echo

ROOT="vire-agent"
V4="$ROOT/v4"
PRICING="$V4/pricing"
SAAS="$V4/saas"
LLM="$V4/llm"
WP="$V4/wp"
RUNNERS="$V4/runners"

mkdir -p "$PRICING" "$SAAS" "$LLM" "$WP" "$RUNNERS"

# ---------------------------------------------------------
# 0) Small helper: load vault if present (from V2)
# ---------------------------------------------------------
cat <<'SH' > "$V4/load_vault.sh"
#!/usr/bin/env bash
set -euo pipefail

VAULT="vire-agent/v2/vault/.vault.env"
if [ -f "$VAULT" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$VAULT"
  set +a
fi
SH
chmod +x "$V4/load_vault.sh"

# =========================================================
# 1) PRICING ENGINE (V4 Option 1)
# - deterministic pricing tiers & feature gating JSON
# =========================================================
cat <<'PY' > "$PRICING/pricing_engine.py"
#!/usr/bin/env python3
import json, sys, datetime

"""
Deterministic tier builder.
Input: product_id, complexity (1-5), target (consumer|pro|enterprise)
Output: pricing.json
"""

def clamp(n, lo, hi): return max(lo, min(hi, n))

def build(product_id, complexity, target):
    complexity = clamp(int(complexity), 1, 5)
    target = target.lower().strip()

    # Base pricing by target
    if target == "consumer":
        base = 9
        step = 6
    elif target == "pro":
        base = 29
        step = 20
    else:
        target = "enterprise"
        base = 99
        step = 60

    # Complexity multiplier
    mult = 1.0 + (complexity - 1) * 0.22

    tiers = [
        {
            "name": "Starter",
            "price_monthly": int(round(base * mult)),
            "features": [
                "Core workflows",
                "Standard support",
                "Single workspace"
            ],
            "limits": {"projects": 3 * complexity, "seats": 1}
        },
        {
            "name": "Pro",
            "price_monthly": int(round((base + step) * mult)),
            "features": [
                "Everything in Starter",
                "Automations",
                "Advanced analytics",
                "Priority support"
            ],
            "limits": {"projects": 10 * complexity, "seats": 5}
        },
        {
            "name": "Enterprise",
            "price_monthly": "Contact Sales",
            "features": [
                "SAML/SSO",
                "Audit logs",
                "Custom SLAs",
                "Dedicated onboarding",
                "Private deployment options"
            ],
            "limits": {"projects": "Unlimited", "seats": "Unlimited"}
        }
    ]

    return {
        "product_id": product_id,
        "target": target,
        "complexity": complexity,
        "generated_at": datetime.datetime.utcnow().isoformat() + "Z",
        "tiers": tiers
    }

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: pricing_engine.py <product_id> <complexity 1-5> <consumer|pro|enterprise>")
        sys.exit(1)

    product_id, complexity, target = sys.argv[1], sys.argv[2], sys.argv[3]
    data = build(product_id, complexity, target)
    out = "vire-agent/export/pricing.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print("✅ Pricing generated:", out)
PY
chmod +x "$PRICING/pricing_engine.py"

# =========================================================
# 2) SAAS LAUNCHER (V4 Option 2)
# - generates tenant-ready site.json + pages for a product
# =========================================================
cat <<'PY' > "$SAAS/saas_launcher.py"
#!/usr/bin/env python3
import json, sys, datetime, re

def slugify(s):
    s = s.strip().lower()
    s = re.sub(r"[^a-z0-9\\s-]", "", s)
    s = re.sub(r"\\s+", "-", s)
    return s

"""
Creates tenant-ready spec:
- site_id = product + tenant
- pages include: Home, Pricing, Demo, Privacy, Terms
"""

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: saas_launcher.py <product_name> <tenant_name> <tone>")
        sys.exit(1)

    product_name = sys.argv[1]
    tenant_name = sys.argv[2]
    tone = sys.argv[3]

    product_slug = slugify(product_name)
    tenant_slug = slugify(tenant_name)

    site = {
        "site_id": f"{product_slug}-{tenant_slug}",
        "product_name": product_name,
        "tenant_name": tenant_name,
        "tone": tone,
        "audience": "early adopters, founders, and enterprise evaluators",
        "keywords": [
            "AI agent frameworks",
            "enterprise-ready platform",
            "secure AI workflows"
        ],
        "pages": [
            "Home",
            "Features",
            "Pricing",
            "Request Demo",
            "Privacy",
            "Terms"
        ],
        "generated_at": datetime.datetime.utcnow().isoformat() + "Z"
    }

    out = "vire-agent/v3/outputs/site.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(site, f, indent=2)
    print("✅ Tenant site.json written:", out)
PY
chmod +x "$SAAS/saas_launcher.py"

# =========================================================
# 3) LLM PROVIDER ABSTRACTION (V4 Option 3)
# - AtmaSphere-first with OpenAI/local fallback
# - used to generate richer copy for pages
# =========================================================
cat <<'PY' > "$LLM/providers.py"
#!/usr/bin/env python3
import os, json, urllib.request

class ProviderError(Exception):
    pass

def _post_json(url, payload, headers=None, timeout=30):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers or {}, method="POST")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))

class AtmaSphereProvider:
    """
    Expects env:
      ATMASPHERE_URL (e.g. http://localhost:9009/v1/generate)
      ATMASPHERE_API_KEY (optional)
    Payload shape can be adapted later—keep minimal now.
    """
    def generate(self, prompt):
        url = os.getenv("ATMASPHERE_URL", "").strip()
        if not url:
            raise ProviderError("ATMASPHERE_URL not set")
        headers = {"Content-Type": "application/json"}
        key = os.getenv("ATMASPHERE_API_KEY", "").strip()
        if key:
            headers["Authorization"] = f"Bearer {key}"
        payload = {"prompt": prompt, "max_tokens": 700}
        out = _post_json(url, payload, headers=headers, timeout=60)
        # expected: {"text":"..."} (adjust if your API differs)
        text = out.get("text") or out.get("output") or ""
        if not text:
            raise ProviderError("AtmaSphere returned empty text")
        return text

class OpenAIProvider:
    """
    Minimal placeholder. Wire to your gateway later.
    Expects:
      OPENAI_GATEWAY_URL (your proxy, not the public OpenAI endpoint)
      OPENAI_API_KEY
    """
    def generate(self, prompt):
        url = os.getenv("OPENAI_GATEWAY_URL", "").strip()
        if not url:
            raise ProviderError("OPENAI_GATEWAY_URL not set")
        key = os.getenv("OPENAI_API_KEY", "").strip()
        if not key:
            raise ProviderError("OPENAI_API_KEY not set")
        headers = {"Content-Type": "application/json", "Authorization": f"Bearer {key}"}
        payload = {"prompt": prompt, "max_tokens": 700}
        out = _post_json(url, payload, headers=headers, timeout=60)
        text = out.get("text") or out.get("output") or ""
        if not text:
            raise ProviderError("OpenAI gateway returned empty text")
        return text

class LocalTemplateProvider:
    """Deterministic fallback; no network."""
    def generate(self, prompt):
        return (
            "Founder’s Note: Vireoka is built by a small team with an agent-first philosophy—"
            "shipping fast, measuring truthfully, and designing for enterprise-grade reliability.\n\n"
            "Summary:\n"
            f"{prompt}\n\n"
            "This page is generated deterministically (no external model)."
        )

def pick_provider():
    # Priority: AtmaSphere -> OpenAI gateway -> deterministic local
    if os.getenv("ATMASPHERE_URL", "").strip():
        return AtmaSphereProvider()
    if os.getenv("OPENAI_GATEWAY_URL", "").strip() and os.getenv("OPENAI_API_KEY", "").strip():
        return OpenAIProvider()
    return LocalTemplateProvider()
PY
chmod +x "$LLM/providers.py"

cat <<'PY' > "$LLM/generate_rich_copy.py"
#!/usr/bin/env python3
import json, pathlib
from providers import pick_provider

"""
Reads: vire-agent/v3/outputs/site.json
Writes: vire-agent/export/pages/*.html (Gutenberg-ready blocks)
Also writes: vire-agent/export/meta.json (SEO meta per page)
"""

site_path = pathlib.Path("vire-agent/v3/outputs/site.json")
if not site_path.exists():
    raise SystemExit("❌ Missing vire-agent/v3/outputs/site.json (run V3 or SaaS launcher first)")

site = json.loads(site_path.read_text(encoding="utf-8"))
provider = pick_provider()

pages_dir = pathlib.Path("vire-agent/export/pages")
pages_dir.mkdir(parents=True, exist_ok=True)

meta = {}

def gut_wrap(inner_html: str) -> str:
    return f"""<!-- wp:group -->
<div class="wp-block-group">
{inner_html}
</div>
<!-- /wp:group -->
"""

for page in site["pages"]:
    prompt = (
        f"Generate a concise, premium, investor-grade landing page section copy for '{page}'.\n"
        f"Product: {site.get('product_name')}\n"
        f"Audience: {site.get('audience')}\n"
        f"Keywords: {', '.join(site.get('keywords', []))}\n"
        "Requirements: E-E-A-T, clear CTA, enterprise tone, no technical IP leakage.\n"
    )

    text = provider.generate(prompt)
    html = f"<h1>{page}</h1>\n<p>{text.replace('\\n','</p>\\n<p>')}</p>\n"
    slug = page.lower().replace(" ", "-")
    (pages_dir / f"{slug}.html").write_text(gut_wrap(html), encoding="utf-8")

    meta[slug] = {
        "title": f"{site.get('product_name')} | {page}",
        "description": f"{site.get('product_name')} — {page}. Enterprise-ready AI platform by Vireoka.",
        "og_title": f"{site.get('product_name')} — {page}",
        "og_description": f"Explore {page} for {site.get('product_name')}.",
    }

(pathlib.Path("vire-agent/export/meta.json")).write_text(json.dumps(meta, indent=2), encoding="utf-8")
print("✅ Rich copy generated. Pages:", len(site["pages"]))
PY
chmod +x "$LLM/generate_rich_copy.py"

# =========================================================
# 4) WORDPRESS PROVISIONING (V4 Option 4)
# - local: creates pages from export/pages using WP-CLI (docker)
# - remote: optional SSH + WP-CLI to create pages on Hostinger
# =========================================================
cat <<'SH' > "$WP/wp_detect.sh"
#!/usr/bin/env bash
set -euo pipefail
docker ps --format '{{.Names}}' | grep -E '^vireoka_wp$' >/dev/null 2>&1
SH
chmod +x "$WP/wp_detect.sh"

cat <<'SH' > "$WP/wp_import_local.sh"
#!/usr/bin/env bash
set -euo pipefail

# Loads vault env if available (not required for local)
bash vire-agent/v4/load_vault.sh || true

WP_CONT="${WP_CONTAINER:-vireoka_wp}"
PAGES_DIR="vire-agent/export/pages"

if ! docker ps --format '{{.Names}}' | grep -q "^${WP_CONT}$"; then
  echo "❌ WordPress container not running: ${WP_CONT}"
  echo "Tip: cd vireoka_local && sudo docker compose up -d"
  exit 1
fi

if [ ! -d "$PAGES_DIR" ]; then
  echo "❌ Missing pages: $PAGES_DIR"
  exit 1
fi

echo "✅ Importing pages into local WP via WP-CLI in container: ${WP_CONT}"

# Ensure wp-cli exists inside container (official image usually doesn't ship it)
# We install wp-cli.phar into /usr/local/bin/wp the first time.
docker exec -it "$WP_CONT" bash -lc '
  if ! command -v wp >/dev/null 2>&1; then
    echo "Installing WP-CLI..."
    curl -sSLo /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    php /tmp/wp-cli.phar --info >/dev/null
    chmod +x /tmp/wp-cli.phar
    mv /tmp/wp-cli.phar /usr/local/bin/wp
  fi
  wp --info | head -n 2
' >/dev/null

for f in "$PAGES_DIR"/*.html; do
  slug="$(basename "$f" .html)"
  title="$(echo "$slug" | sed 's/-/ /g' | awk "{ for (i=1;i<=NF;i++) \$i=toupper(substr(\$i,1,1)) substr(\$i,2); print }")"
  echo "→ Creating/Updating: $title ($slug)"
  # Create if missing; otherwise update content.
  docker exec -i "$WP_CONT" bash -lc "
    ID=\$(wp post list --post_type=page --name='$slug' --field=ID --allow-root 2>/dev/null | head -n 1 || true)
    if [ -z \"\$ID\" ]; then
      wp post create --post_type=page --post_status=publish --post_title=\"$title\" --post_name='$slug' --allow-root --porcelain
    else
      echo \$ID
    fi
  " >/dev/null

  # Update content from file
  docker exec -i "$WP_CONT" bash -lc "
    ID=\$(wp post list --post_type=page --name='$slug' --field=ID --allow-root 2>/dev/null | head -n 1)
    wp post update \"\$ID\" --post_content=\"\$(cat)\" --allow-root >/dev/null
  " < "$f"
done

echo "✅ Local WP pages imported."
echo "🌐 Visit: http://localhost:8085"
SH
chmod +x "$WP/wp_import_local.sh"

cat <<'SH' > "$WP/wp_import_remote_hostinger.sh"
#!/usr/bin/env bash
set -euo pipefail

# Requires: vconfig.sh (in vireoka-tools) OR env vars:
# REMOTE_HOST REMOTE_USER REMOTE_PORT REMOTE_ROOT
# Also requires remote wp-cli command: wp

PAGES_DIR="vire-agent/export/pages"
[ -d "$PAGES_DIR" ] || { echo "❌ Missing $PAGES_DIR"; exit 1; }

# Try to source vireoka-tools/vconfig.sh if present
if [ -f "vireoka-tools/vconfig.sh" ]; then
  # shellcheck disable=SC1091
  source "vireoka-tools/vconfig.sh"
fi

: "${REMOTE_HOST:?REMOTE_HOST missing}"
: "${REMOTE_USER:?REMOTE_USER missing}"
: "${REMOTE_PORT:?REMOTE_PORT missing}"
: "${REMOTE_ROOT:?REMOTE_ROOT missing}"

echo "✅ Remote import to Hostinger:"
echo "  $REMOTE_USER@$REMOTE_HOST:$REMOTE_ROOT"

# Detect wp-cli on remote
WP_CMD="$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "command -v wp || true")"
[ -n "$WP_CMD" ] || { echo "❌ wp-cli not found on remote. Install WP-CLI or enable it in hosting."; exit 1; }

for f in "$PAGES_DIR"/*.html; do
  slug="$(basename "$f" .html)"
  title="$(echo "$slug" | sed 's/-/ /g' | awk "{ for (i=1;i<=NF;i++) \$i=toupper(substr(\$i,1,1)) substr(\$i,2); print }")"
  echo "→ Remote page: $title ($slug)"

  CONTENT_B64="$(base64 -w0 "$f")"

  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" bash -lc "'
    set -e
    cd \"$REMOTE_ROOT\"
    ID=\$(wp post list --post_type=page --name=\"$slug\" --field=ID 2>/dev/null | head -n 1 || true)
    if [ -z \"\$ID\" ]; then
      ID=\$(wp post create --post_type=page --post_status=publish --post_title=\"$title\" --post_name=\"$slug\" --porcelain)
    fi
    echo \"$CONTENT_B64\" | base64 -d > /tmp/vire_page.html
    wp post update \"\$ID\" --post_content=\"\$(cat /tmp/vire_page.html)\" >/dev/null
    rm -f /tmp/vire_page.html
  '"
done

echo "✅ Remote pages imported to production."
SH
chmod +x "$WP/wp_import_remote_hostinger.sh"

# =========================================================
# 5) ONE COMMAND V4 RUNNER
# - pricing -> rich copy -> V2 wrapper -> dashboard -> optional WP import
# =========================================================
cat <<'SH' > "$RUNNERS/vire_v4_run.sh"
#!/usr/bin/env bash
set -euo pipefail

PRODUCT_ID="${1:-vireoka-product}"
COMPLEXITY="${2:-3}"
TARGET="${3:-enterprise}"
IMPORT_LOCAL="${4:-no}"   # yes/no

echo "⚙️ Vire V4 Run"
echo "Product: $PRODUCT_ID | Complexity: $COMPLEXITY | Target: $TARGET | ImportLocal: $IMPORT_LOCAL"
echo

# Load vault if present (for AtmaSphere/OpenAI providers)
bash vire-agent/v4/load_vault.sh || true

# 1) Pricing
python3 vire-agent/v4/pricing/pricing_engine.py "$PRODUCT_ID" "$COMPLEXITY" "$TARGET"

# 2) Rich copy (AtmaSphere/OpenAI/local fallback)
python3 -c "import sys; sys.path.insert(0,'vire-agent/v4/llm'); import generate_rich_copy" >/dev/null 2>&1 || true
python3 vire-agent/v4/llm/generate_rich_copy.py

# 3) Inject V2 wrapper classes (if V2 exists)
if [ -f "vire-agent/v2/theme/bodyclass_inject.py" ]; then
  python3 vire-agent/v2/theme/bodyclass_inject.py || true
fi

# 4) Render dashboard (if V2 exists)
if [ -f "vire-agent/v2/dashboard/render_dashboard.py" ]; then
  python3 vire-agent/v2/dashboard/render_dashboard.py || true
fi

# 5) Optionally import into local WP
if [ "$IMPORT_LOCAL" = "yes" ]; then
  bash vire-agent/v4/wp/wp_import_local.sh
fi

echo
echo "✅ V4 complete"
echo "Artifacts:"
echo " - export/pages/*"
echo " - export/meta.json"
echo " - export/schema.json (from V3 if you ran it)"
echo " - export/pricing.json"
echo " - dashboard: vire-agent/v2/dashboard/dashboard.html (if V2 installed)"
SH
