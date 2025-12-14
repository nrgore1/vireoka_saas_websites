#!/bin/bash

function vk_git_sync() {
  if [[ "$GIT_AUTO_PUSH" == "true" ]]; then
    echo "🔄 Git auto-commit…"
    git add -A
    git commit -m "Auto-sync $(date +'%Y-%m-%d %H:%M:%S')" || true
    git push origin "$GIT_BRANCH" || echo "⚠️ Git push failed."
  fi
}

function vk_notify() {
  msg="$1"
  echo "🔔 Notify: $msg"

  if [[ -n "$WEBHOOK_URL" ]]; then
    curl -s -X POST -H 'Content-Type: application/json' \
      -d "{\"text\": \"$msg\"}" \
      "$WEBHOOK_URL" > /dev/null 2>&1
  fi
}

function vk_write_status() {
  STATUS_FILE="$LOCAL_STATUS"

  echo "{\"timestamp\": \"$(date)\", \"mode\": \"$1\", \"message\": \"$2\"}" > "$STATUS_FILE"

  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
    "mkdir -p $REMOTE_STATUS_DIR && echo '{\"timestamp\": \"$(date)\", \"message\": \"$2\"}' > $REMOTE_STATUS"
}

function vk_write_conflicts() {
  echo "$1" > "$LOCAL_CONFLICTS"

  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
    "mkdir -p $REMOTE_STATUS_DIR && echo '$1' > $REMOTE_CONFLICTS"
}
CONFLICTS=""

while IFS='|' read -r file ts_remote; do
  ts_local=$(grep "^$file|" "$TMP_LOCAL" | cut -d'|' -f2)
  if [[ -n "$ts_local" && "$ts_local" != "$ts_remote" ]]; then
    CONFLICTS+="{\"file\":\"$file\",\"local\":\"$ts_local\",\"remote\":\"$ts_remote\"},"
  fi
done < "$TMP_REMOTE"

if [[ -n "$CONFLICTS" ]]; then
  CONFLICTS_JSON="{\"conflicts\":[$(echo "$CONFLICTS" | sed 's/,$//')]}"
  echo "⚠️ Conflicts detected!"
  vk_write_conflicts "$CONFLICTS_JSON"
  vk_notify "Vireoka Sync: Conflicts detected in plugins"
fi
echo "🧹 Cleaning orphaned files..."
eval $RSYNC --delete "$REMOTE_USER@$REMOTE_HOST:\"$REMOTE_PLUGINS/\"" "$LOCAL_PLUGINS/"
eval $RSYNC --delete "$LOCAL_PLUGINS/" "$REMOTE_USER@$REMOTE_HOST:\"$REMOTE_PLUGINS/\""
vk_git_sync
vk_notify "Plugins sync completed successfully."
vk_write_status "plugins" "Plugins synced cleanly."
