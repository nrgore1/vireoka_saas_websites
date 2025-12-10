#!/bin/bash
#
#  Vireoka Two-Way Sync v4.0 — Plugins
# ----------------------------------------
#  • Detects remote ↔ local changes in plugins
#  • Syncs only necessary files
#  • Backs up server before pushing
#  • Detects conflicts via timestamps
#  • Writes conflict logs locally + remotely
#

set -euo pipefail

CONFIG_FILE="$(dirname "$0")/vconfig.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Missing vconfig.sh — aborting."
  exit 1
fi
source "$CONFIG_FILE"

echo "🔁  Vireoka Two-Way Sync v4.0 (Plugins)"
echo "---------------------------------------"

TMP_REMOTE="/tmp/vireoka_remote_plugins.txt"
TMP_LOCAL="/tmp/vireoka_local_plugins.txt"
REMOTE_SORT="/tmp/vireoka_remote_sorted.txt"
LOCAL_SORT="/tmp/vireoka_local_sorted.txt"

mkdir -p /tmp

# 1) Remote file list (plugins)
echo "📡 Reading remote plugin files..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
  "cd '$REMOTE_PLUGINS' && find . -type f -printf '%P|%T@\\n'" \
  > "$TMP_REMOTE" || echo "" > "$TMP_REMOTE"

# 2) Local file list
echo "💻 Reading local plugin files..."
cd "$LOCAL_PLUGINS"
find . -type f -printf "%P|%T@\n" > "$TMP_LOCAL"

sort "$TMP_REMOTE" > "$REMOTE_SORT"
sort "$TMP_LOCAL" > "$LOCAL_SORT"

# 3) New files on each side
NEW_REMOTE=$(comm -23 "$REMOTE_SORT" "$LOCAL_SORT" || true)
NEW_LOCAL=$(comm -13 "$REMOTE_SORT" "$LOCAL_SORT" || true)

# 4) Conflicts (same path, different timestamps)
echo "🔍 Checking for plugin conflicts..."
CONFLICTS=""

while IFS='|' read -r path_remote ts_remote; do
  [[ -z "$path_remote" ]] && continue
  ts_local=$(grep "^$path_remote|" "$LOCAL_SORT" | cut -d'|' -f2 || true)
  if [[ -n "$ts_local" && "$ts_local" != "$ts_remote" ]]; then
    CONFLICTS+="$path_remote|$ts_local|$ts_remote"$'\n'
  fi
done < "$REMOTE_SORT"

if [[ -n "$CONFLICTS" ]]; then
  echo "⚠️  Plugin conflicts detected:"
  echo "$CONFLICTS" | sed 's/|/ → /g'

  echo "$CONFLICTS" > "$LOCAL_CONFLICTS_JSON"

  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p '$REMOTE_STATUS_DIR'"
  printf '%s\n' "$CONFLICTS" | ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
    "cat > '$REMOTE_CONFLICTS_JSON'"
else
  echo "✔ No plugin conflicts."
fi

# 5) Pull from remote → local if remote has new/extra files
if [[ -n "$NEW_REMOTE" ]]; then
  echo "⬇️  Remote plugins have updates → pulling..."
  $RSYNC $EXCLUDES \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/" \
    "$LOCAL_PLUGINS/"
fi

# 6) Push from local → remote if local has new/extra files
if [[ -n "$NEW_LOCAL" ]]; then
  echo "⬆️  Local plugins have updates → pushing..."

  "$(dirname "$0")/vbackup.sh"

  $RSYNC $EXCLUDES \
    "$LOCAL_PLUGINS/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/"

  "$(dirname "$0")/vpost-sync.sh"
fi

echo "---------------------------------------"
echo "✔ Plugin two-way sync complete."
echo "---------------------------------------"
