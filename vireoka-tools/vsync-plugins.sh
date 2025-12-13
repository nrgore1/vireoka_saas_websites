#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🔌 SYNC: Plugins (V6 active-only, changed-only via rsync)"

mkdir -p "$LOCAL_PLUGINS" "$LOCAL_STATUS_DIR"

ALLOWLIST="$LOCAL_STATUS_DIR/active_plugins.txt"
"$BASE_DIR/vsync-active-list.sh" plugins "$ALLOWLIST" || true

# If allowlist is empty -> fallback to full folder sync
if [ ! -s "$ALLOWLIST" ]; then
  echo "ℹ️  No active plugin list found. Falling back to full plugin sync."
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/" \
    "$LOCAL_PLUGINS/"
  if [ "$SYNC_MODE" != "pull-only" ]; then
    "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
      "$LOCAL_PLUGINS/" \
      "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/"
  fi
  echo "✔ Plugins sync complete."
  exit 0
fi

echo "✅ Active plugins allowlist:"
cat "$ALLOWLIST" | sed 's/^/ - /g'

# Build rsync include rules: include each active plugin folder, exclude everything else
INCLUDES=()
while read -r plugin; do
  [ -z "$plugin" ] && continue
  INCLUDES+=(--include "/$plugin/***")
done < "$ALLOWLIST"

# Always include top-level dirs so rsync can traverse
INCLUDES+=(--include "*/" --exclude "*")

# Pull remote → local (only active plugin dirs; rsync only writes changed files)
echo "⬇️  Pulling active plugin updates (remote → local)..."
"$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "${INCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/" \
  "$LOCAL_PLUGINS/"

# Push local → remote (only if not pull-only)
if [ "$SYNC_MODE" != "pull-only" ]; then
  echo "⬆️  Pushing active plugin updates (local → remote)..."
  "$BASE_DIR/vbackup.sh" || true
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "${INCLUDES[@]}" \
    "$LOCAL_PLUGINS/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/"
fi

echo "✔ Plugins sync complete."
