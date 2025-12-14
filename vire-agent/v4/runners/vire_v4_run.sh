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
