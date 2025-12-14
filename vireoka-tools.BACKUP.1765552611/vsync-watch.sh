#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "👀 Vireoka Watch Mode (plugins + themes)"
echo "    Local root: $LOCAL_ROOT"
echo

if ! command -v inotifywait >/dev/null 2>&1; then
  echo "❌ inotifywait not found. Install with:"
  echo "   sudo apt install inotify-tools"
  exit 1
fi

WATCH_PATHS=()
[ -d "$LOCAL_PLUGINS" ] && WATCH_PATHS+=("$LOCAL_PLUGINS")
[ -d "$LOCAL_THEMES" ] && WATCH_PATHS+=("$LOCAL_THEMES")

if [ ${#WATCH_PATHS[@]} -eq 0 ]; then
  echo "⚠️  No local plugins/themes folders found under $LOCAL_ROOT"
  exit 0
fi

"$BASE_DIR/vsync-notify.sh" "Vireoka Watch" "Started watching for changes..." || true

while true; do
  inotifywait -r -e modify,create,delete,move "${WATCH_PATHS[@]}" >/dev/null 2>&1
  echo
  echo "🔄 Change detected → syncing..."
  "$BASE_DIR/vsync.sh" plugins || true
  "$BASE_DIR/vsync.sh" themes || true
done
