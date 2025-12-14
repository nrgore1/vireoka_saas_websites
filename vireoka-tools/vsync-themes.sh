#!/bin/bash
set -e
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🎨 SYNC: Themes (delta)"

MANIFEST="$MANIFEST_DIR/themes.manifest"

REMOTE_HASH=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
  "cd \"$REMOTE_THEMES\" && find . -type f -printf '%P|%T@\n' | sha1sum" \
  | awk '{print $1}')

LOCAL_HASH="$(cat "$MANIFEST" 2>/dev/null || true)"

if [ "$REMOTE_HASH" = "$LOCAL_HASH" ]; then
  echo "⚡ Themes unchanged — manifest hit"
  exit 0
fi

echo "$REMOTE_HASH" > "$MANIFEST"

ACTIVE_THEME=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
  "wp theme list --status=active --field=name --path=\"$REMOTE_ROOT\"" \
  | head -n 1)

if [ -z "$ACTIVE_THEME" ]; then
  echo "⚠️ Could not detect active theme; falling back to syncing only 'vireoka_core' if present."
  ACTIVE_THEME="vireoka_core"
fi

"$RSYNC_BIN" $RSYNC_OPTS \
  --include="/$ACTIVE_THEME/**" \
  --exclude="*" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" \
  "$LOCAL_THEMES/"

echo "✔ Theme synced: $ACTIVE_THEME"
