#!/usr/bin/env bash
set -euo pipefail

PROMPT="${1:?prompt required}"
PRODUCT="${2:?product required}"
TONE="${3:-elite-neural-luxe}"

echo "🚀 Vire V5 Agentic One-Command"
echo "1) LLM generate (prompt → pages)"
bash "vire-agent/v5/agentic/prompt_to_site.sh" "$PROMPT" "$PRODUCT" "$TONE"

echo
echo "2) Apply to LOCAL WP (Docker)"
if [ -x "vire-agent/v5/wp/local_wp_apply.sh" ]; then
  bash "vire-agent/v5/wp/local_wp_apply.sh"
else
  echo "⚠ Missing: vire-agent/v5/wp/local_wp_apply.sh"
  echo "   (Install V5 first, then re-run.)"
fi

echo
echo "3) Deploy to Hostinger"
if [ -x "vire-agent/v5/deploy/deploy_to_hostinger.sh" ]; then
  bash "vire-agent/v5/deploy/deploy_to_hostinger.sh"
else
  echo "⚠ Missing: vire-agent/v5/deploy/deploy_to_hostinger.sh"
  echo "   (If your V5 uses vsync scripts, run: ./vireoka-tools/vsync.sh all)"
fi

echo
echo "4) Verify + Screenshot + PDF report"
if [ -x "vire-agent/v5/verify/verify_and_report.sh" ]; then
  bash "vire-agent/v5/verify/verify_and_report.sh"
else
  echo "⚠ Missing: vire-agent/v5/verify/verify_and_report.sh"
fi

echo
echo "✅ Agentic V5 complete."
echo "Local: http://localhost:8085"
echo "Live : https://vireoka.com"
echo "Report: vire-agent/v5/report/report.html | report.pdf"
