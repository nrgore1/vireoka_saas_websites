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
