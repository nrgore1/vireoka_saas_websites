#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

REMOTE_CMD='
set -euo pipefail

if ! command -v inotifywait >/dev/null 2>&1; then
  echo "ERROR: inotifywait not found on remote."
  echo "Install: apt-get install -y inotify-tools (or equivalent)"
  exit 2
fi

watch_dir() {
  local label="$1"
  local dir="$2"

  inotifywait -m -r \
    -e close_write,move,create,delete \
    --format "%e|%w%f" "$dir" \
  | while IFS="|" read -r ev path; do
      echo "${label}|${ev}|${path}"
    done
}

watch_dir plugins "'"$REMOTE_PLUGINS"'" &
watch_dir themes  "'"$REMOTE_THEMES"'"  &
watch_dir uploads "'"$REMOTE_UPLOADS"'" &

wait
'

echo "🛰  Remote inotify watcher (SSH)"
echo "------------------------------------------"
echo "Remote: $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
echo

ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$REMOTE_CMD" \
| while IFS='|' read -r scope ev path; do
    [ -z "${scope:-}" ] && continue

    echo "📡 Remote change: scope=$scope event=$ev path=$path"

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
