#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🧠 Vire AI Diff Explainer"
echo "------------------------------------------"

# Inputs (prefer JSON)
CONFLICTS_JSON="${LOCAL_STATUS_DIR}/conflicts.json"
CONFLICTS_TXT="${LOCAL_STATUS_DIR}/conflicts.txt"

# Output
OUT_MD="${LOCAL_STATUS_DIR}/ai_conflicts_report.md"
OUT_JSON="${LOCAL_STATUS_DIR}/ai_conflicts_report.json"

python3 "$BASE_DIR/vire_ai_diff_explain.py" \
  --conflicts-json "$CONFLICTS_JSON" \
  --conflicts-txt  "$CONFLICTS_TXT" \
  --out-md         "$OUT_MD" \
  --out-json       "$OUT_JSON"

echo "✅ Report written:"
echo "   - $OUT_MD"
echo "   - $OUT_JSON"
echo

# Best-effort publish to remote status dir
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" >/dev/null 2>&1 || true
scp -P "$REMOTE_PORT" "$OUT_MD"   "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS_DIR/ai_conflicts_report.md"   >/dev/null 2>&1 || true
scp -P "$REMOTE_PORT" "$OUT_JSON" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS_DIR/ai_conflicts_report.json" >/dev/null 2>&1 || true

echo "🌐 Remote publish (best effort):"
echo "   - $REMOTE_STATUS_DIR/ai_conflicts_report.md"
echo "   - $REMOTE_STATUS_DIR/ai_conflicts_report.json"
