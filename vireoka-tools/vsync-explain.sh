#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

PLAN="$LOCAL_STATUS_DIR/resolution_plan.json"
[ -f "$PLAN" ] || { echo "❌ Missing plan. Run: ./vsync-plan.sh"; exit 1; }

OUT_MD="$LOCAL_STATUS_DIR/vire6_conflicts_explained.md"

python3 "$BASE_DIR/vire6_llm.py" "$PLAN" "$OUT_MD"

# Best-effort remote publish
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" >/dev/null 2>&1 || true
scp -P "$REMOTE_PORT" "$OUT_MD" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS_DIR/vire6_conflicts_explained.md" >/dev/null 2>&1 || true

echo "✅ Explanation ready:"
echo " - $OUT_MD"
echo " - Remote (best effort): $REMOTE_STATUS_DIR/vire6_conflicts_explained.md"
