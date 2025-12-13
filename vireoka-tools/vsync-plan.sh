#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

POLICY="$BASE_DIR/vire_policy/vire_policy.yaml"

CONFLICTS_JSON="$LOCAL_STATUS_DIR/conflicts.json"
CONFLICTS_TXT="$LOCAL_STATUS_DIR/conflicts.txt"
OUT_PLAN="$LOCAL_STATUS_DIR/resolution_plan.json"

# Conflicts may be stored differently in your suite; keep compatibility:
# - If conflicts.json doesn't exist, create minimal empty structure.
if [ ! -f "$CONFLICTS_JSON" ]; then
  echo '{"conflicts":[]}' > "$CONFLICTS_JSON"
fi
if [ ! -f "$CONFLICTS_TXT" ]; then
  : > "$CONFLICTS_TXT"
fi

python3 "$BASE_DIR/vire6_policy_engine.py" \
  --policy "$POLICY" \
  --conflicts-json "$CONFLICTS_JSON" \
  --conflicts-txt "$CONFLICTS_TXT" \
  --out-plan "$OUT_PLAN"

echo "📌 Plan: $OUT_PLAN"

# Best-effort remote publish
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" >/dev/null 2>&1 || true
scp -P "$REMOTE_PORT" "$OUT_PLAN" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS_DIR/resolution_plan.json" >/dev/null 2>&1 || true
echo "🌐 Remote publish (best effort): $REMOTE_STATUS_DIR/resolution_plan.json"
