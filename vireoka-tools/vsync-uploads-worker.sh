#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

INTERVAL="${VIRE_UPLOADS_FLUSH_INTERVAL:-60}"   # uploads are low priority
MAX_BATCH="${VIRE_UPLOADS_FLUSH_MAX:-400}"

echo "🐢 Uploads worker (low priority lane)"
echo "Flush interval: ${INTERVAL}s"
echo "Max batch:      ${MAX_BATCH}"
echo

while true; do
  bash "$BASE_DIR/vsync-queue.sh" flush "$MAX_BATCH" || true
  sleep "$INTERVAL"
done
