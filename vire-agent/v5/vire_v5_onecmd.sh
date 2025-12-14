#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/bin/common.sh"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"         # .../vire-agent
V5="$ROOT_DIR/v5"
REPO_ROOT="$(cd "$ROOT_DIR/.." && pwd)"              # .../vireoka_website

PROMPT="${1:-}"
PRODUCT="${2:-Vireoka Product}"
TONE="${3:-elite-neural-luxe}"

[ -n "$PROMPT" ] || die "Usage: ./vire-agent/v5/vire_v5_onecmd.sh \"<prompt>\" \"<product name>\" \"<tone>\""

echo "🧠 1) Prompt → site.json"
python3 "$V5/gen/prompt_to_site.py" "$PROMPT" "$PRODUCT" "$TONE" "$V5/outputs/site.json"

echo "🧱 2) site.json → Gutenberg pages"
python3 "$V5/wp/wp_static_export.py"

echo "🐳 3) Ensure local WP Docker is up"
need_cmd docker
cd "$REPO_ROOT/vireoka_local"
docker compose up -d

echo "�� 4) Apply pages + theme to local WP"
cd "$REPO_ROOT"
bash "$V5/wp/local_wp_apply.sh"

echo "🚚 5) Deploy to Hostinger (files + DB)"
bash "$V5/deploy/deploy_to_hostinger.sh"

echo "🧪 6) Verify + screenshot report"
bash "$V5/verify/verify_and_report.sh"

echo
echo "✅ Vire V5 complete."
echo "Local: http://localhost:8085"
echo "Live:  https://vireoka.com"
echo "Report: vire-agent/v5/report/report.html"
