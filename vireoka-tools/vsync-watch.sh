#!/bin/bash
#
#  Vireoka Watcher v1.0
#  • Watches local plugins + wp-content for changes
#  • On change, runs: vsync.sh + vsite-sync.sh
#

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$BASE_DIR/vconfig.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Missing vconfig.sh — aborting."
  exit 1
fi
source "$CONFIG_FILE"

echo "👀 Vireoka Watch Mode (plugins + site)"
echo "   Local plugins : $LOCAL_PLUGINS"
echo "   Local wp      : $LOCAL_WP_ROOT"
echo "---------------------------------------"

VSYNC_PLUGINS="$BASE_DIR/vsync.sh"
VSYNC_SITE="$BASE_DIR/vsite-sync.sh"

run_sync() {
  echo "⚡ Change detected → syncing..."
  "$VSYNC_PLUGINS"
  "$VSYNC_SITE"
  echo "✅ Sync cycle finished. Watching again..."
}

if command -v inotifywait >/dev/null 2>&1; then
  echo "📡 Using inotifywait for live watching..."
  while true; do
    inotifywait -r -e modify,create,delete,move \
      "$LOCAL_PLUGINS" "$LOCAL_WP_CONTENT" >/dev/null 2>&1
    run_sync
  done
else
  echo "⚠️  inotifywait not found. Falling back to 15s polling."
  LAST_HASH=""

  while true; do
    CURRENT_HASH=$(find "$LOCAL_PLUGINS" "$LOCAL_WP_CONTENT" -type f -printf '%P %T@\n' | md5sum | cut -d' ' -f1)
    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
      LAST_HASH="$CURRENT_HASH"
      run_sync
    fi
    sleep 15
  done
fi
