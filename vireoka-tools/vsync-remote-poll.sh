#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

INTERVAL="${VIRE_REMOTE_POLL_INTERVAL:-10}"
STATE_DIR="$LOCAL_STATUS_DIR/remote_poll"
mkdir -p "$STATE_DIR"

poll_scope() {
  local scope="$1"
  local remote_dir="$2"
  local state_file="$STATE_DIR/$scope.prev"

  TMP="$(mktemp)"

  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
    "cd \"$remote_dir\" && find . -type f -printf '%P|%T@\\n' | sort" \
    > "$TMP" || true

  if [ -f "$state_file" ]; then
    comm -13 "$state_file" "$TMP" | while IFS='|' read -r path ts; do
      echo "📡 Remote change: scope=$scope event=MODIFIED path=$path"
      case "$scope" in
        plugins|themes)
          bash "$BASE_DIR/vsync.sh" "$scope" silent || true
          bash "$BASE_DIR/vsync-git-debounce.sh" touch "$scope" || true
          bash "$BASE_DIR/vire-ai-predict-next.sh" record "$scope" "$path" || true
          ;;
        uploads)
          bash "$BASE_DIR/vsync-queue.sh" enqueue uploads "$path" || true
          bash "$BASE_DIR/vire-ai-predict-next.sh" record uploads "$path" || true
          ;;
      esac
    done
  fi

  mv "$TMP" "$state_file"
}

echo "🛰  Remote polling watcher (Layer 4 fallback)"
echo "Interval: ${INTERVAL}s"
echo

while true; do
  poll_scope plugins "$REMOTE_PLUGINS"
  poll_scope themes  "$REMOTE_THEMES"
  poll_scope uploads "$REMOTE_UPLOADS"
  sleep "$INTERVAL"
done
