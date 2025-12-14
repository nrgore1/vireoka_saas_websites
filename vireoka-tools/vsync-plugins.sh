#!/bin/bash
set -e
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🔌 SYNC: Plugins (delta)"

MANIFEST="$MANIFEST_DIR/plugins.manifest"

REMOTE_HASH=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
  "cd \"$REMOTE_PLUGINS\" && find . -type f -printf '%P|%T@\n' | sha1sum" \
  | awk '{print $1}')

LOCAL_HASH="$(cat "$MANIFEST" 2>/dev/null || true)"

if [ "$REMOTE_HASH" = "$LOCAL_HASH" ]; then
  echo "⚡ Plugins unchanged — manifest hit"
  exit 0
fi

echo "$REMOTE_HASH" > "$MANIFEST"

ACTIVE_PLUGINS="$LOCAL_STATUS_DIR/active_plugins.txt"
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
  "wp plugin list --status=active --field=name --path=\"$REMOTE_ROOT\"" \
  > "$ACTIVE_PLUGINS" || true

RSYNC_FILTERS=()
if [ -s "$ACTIVE_PLUGINS" ]; then
  while read -r p; do
    [ -z "$p" ] && continue
    RSYNC_FILTERS+=(--include="/$p/**")
  done < "$ACTIVE_PLUGINS"
fi
# Always include a minimal allowlist for WP’s plugin root files
RSYNC_FILTERS+=(--include="/index.php" --include="/**/.gitkeep")
RSYNC_FILTERS+=(--exclude="*")

"$RSYNC_BIN" $RSYNC_OPTS \
  "${RSYNC_FILTERS[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/" \
  "$LOCAL_PLUGINS/"

echo "✔ Plugins synced (active-only when available)"
