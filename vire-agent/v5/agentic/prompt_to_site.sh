#!/usr/bin/env bash
set -euo pipefail

PROMPT="${1:?prompt required}"
PRODUCT="${2:?product required}"
TONE="${3:-elite-neural-luxe}"

echo "🧠 Agentic V5: prompt → copy+layout → Gutenberg pages"
python3 "vire-agent/v5/agentic/llm_sitegen.py" \
  --prompt "$PROMPT" \
  --product "$PRODUCT" \
  --tone "$TONE" \
  --out "vire-agent/v5/outputs"

echo "✅ Generated:"
echo " - vire-agent/v5/outputs/site.json"
echo " - vire-agent/v5/outputs/pages/*.html"
