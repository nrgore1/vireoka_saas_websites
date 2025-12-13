#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🧪 Vire 6 SIMULATE (dry-run rsync for changed files only)"
echo "------------------------------------------"
echo "This does NOT write anything. It shows what would change."
echo

# rsync already avoids unchanged writes; dry-run prints diffs.
echo "🔌 Plugins (dry-run):"
"$RSYNC_BIN" -n $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/" "$LOCAL_PLUGINS/" || true
echo

echo "🎨 Themes (dry-run):"
"$RSYNC_BIN" -n $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" "$LOCAL_THEMES/" || true
echo

echo "🖼 Uploads (dry-run):"
"$RSYNC_BIN" -n $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_UPLOADS/" "$LOCAL_UPLOADS/" || true
echo

echo "✅ Simulation complete."
