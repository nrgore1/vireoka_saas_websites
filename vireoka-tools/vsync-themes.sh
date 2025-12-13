#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🎨 SYNC: WordPress Themes (V6 active-only, changed-only via rsync)"

mkdir -p "$LOCAL_THEMES" "$LOCAL_STATUS_DIR"

ALLOWLIST="$LOCAL_STATUS_DIR/active_themes.txt"
"$BASE_DIR/vsync-active-list.sh" themes "$ALLOWLIST" || true

if [ ! -s "$ALLOWLIST" ]; then
  echo "ℹ️  No active theme list found. Falling back to full theme sync."
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" \
    "$LOCAL_THEMES/"
  if [ "$SYNC_MODE" != "pull-only" ]; then
    "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
      "$LOCAL_THEMES/" \
      "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/"
  fi
  echo "✔ Themes sync complete."
  exit 0
fi

echo "✅ Active themes allowlist:"
cat "$ALLOWLIST" | sed 's/^/ - /g'

INCLUDES=()
while read -r theme; do
  [ -z "$theme" ] && continue
  INCLUDES+=(--include "/$theme/***")
done < "$ALLOWLIST"

INCLUDES+=(--include "*/" --exclude "*")

echo "⬇️  Pulling active theme updates (remote → local)..."
"$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "${INCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" \
  "$LOCAL_THEMES/"

if [ "$SYNC_MODE" != "pull-only" ]; then
  echo "⬆️  Pushing active theme updates (local → remote)..."
  "$BASE_DIR/vbackup.sh" || true
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "${INCLUDES[@]}" \
    "$LOCAL_THEMES/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/"
fi

echo "✔ Themes sync complete."
