#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "�� SYNC: WordPress Themes"

mkdir -p "$LOCAL_THEMES"

TMP_REMOTE=$(mktemp /tmp/vk_themes_remote.XXXXXX)
TMP_LOCAL=$(mktemp /tmp/vk_themes_local.XXXXXX)

# 1) Capture remote theme files
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
  "cd \"$REMOTE_THEMES\" && find . -type f -printf '%P|%T@\\n'" \
  > "$TMP_REMOTE" || echo "" > "$TMP_REMOTE"

# 2) Capture local theme files
cd "$LOCAL_THEMES" 2>/dev/null || mkdir -p "$LOCAL_THEMES" && cd "$LOCAL_THEMES"
find . -type f -printf "%P|%T@\n" > "$TMP_LOCAL" || echo "" > "$TMP_LOCAL"

REMOTE_SORT="${TMP_REMOTE}_sorted"
LOCAL_SORT="${TMP_LOCAL}_sorted"
sort "$TMP_REMOTE" > "$REMOTE_SORT"
sort "$TMP_LOCAL" > "$LOCAL_SORT"

NEW_REMOTE=$(comm -23 "$REMOTE_SORT" "$LOCAL_SORT" || true)
NEW_LOCAL=$(comm -13 "$REMOTE_SORT" "$LOCAL_SORT" || true)

# 3) Conflict Detection
CONFLICTS=""
while IFS='|' read -r path ts_remote; do
  [ -z "$path" ] && continue
  ts_local=$(grep "^$path|" "$LOCAL_SORT" | cut -d'|' -f2 || true)
  if [ -n "$ts_local" ] && [ "$ts_local" != "$ts_remote" ]; then
    CONFLICTS+="$path|$ts_local|$ts_remote"$'\n'
  fi
done < "$REMOTE_SORT"

if [ -n "$CONFLICTS" ]; then
  echo "⚠️  Theme conflicts detected:"
  echo "$CONFLICTS" | sed 's/|/  →  /g'

  printf '%s\n' "$CONFLICTS" > "$LOCAL_CONFLICTS"

  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" || true
  printf '%s\n' "$CONFLICTS" | ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
    "cat > \"$REMOTE_CONFLICTS\"" || true
fi

# 4) Pull remote → local
if [ -n "$NEW_REMOTE" ] || [ "$SYNC_MODE" = "pull-only" ]; then
  echo "⬇️  Pulling theme updates..."
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" \
    "$LOCAL_THEMES/"
fi

# 5) Push local → remote
if [ "$SYNC_MODE" != "pull-only" ] && [ -n "$NEW_LOCAL" ]; then
  echo "⬆️  Pushing theme updates..."
  "$BASE_DIR/vbackup.sh" || true
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "$LOCAL_THEMES/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/"
fi

rm -f "$TMP_REMOTE" "$TMP_LOCAL" "$REMOTE_SORT" "$LOCAL_SORT"

echo "✔ Themes sync complete."
