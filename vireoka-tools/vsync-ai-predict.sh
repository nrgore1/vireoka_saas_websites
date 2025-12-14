#!/bin/bash
set -e
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

[ "${VIRE_AI_PREDICT:-0}" != "1" ] && exit 0

echo "🧠 Vire AI prewarm (passive)"

# If conflicts txt exists, capture top-level dirs as “likely to change”
if [ -f "$LOCAL_CONFLICTS" ]; then
  awk -F'|' '{print $1}' "$LOCAL_CONFLICTS" 2>/dev/null \
    | sed 's#/[^/]*$##' \
    | sort -u | head -n 8 \
    > "$LOCAL_STATUS_DIR/ai_predicted_paths.txt" || true
fi
