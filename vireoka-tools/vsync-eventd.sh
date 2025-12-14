#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

DEBOUNCE="${VIRE_EVENT_DEBOUNCE_SEC:-2}"

need() { command -v "$1" >/dev/null 2>&1; }

if ! need inotifywait; then
  echo "❌ inotifywait not found."
  echo "Install: sudo apt-get update && sudo apt-get install -y inotify-tools"
  exit 1
fi

echo "⚡ Vire Event Daemon (local) — debounce=${DEBOUNCE}s"
echo "Watching:"
echo "  plugins: $LOCAL_PLUGINS"
echo "  themes : $LOCAL_THEMES"
echo "  uploads: $LOCAL_UPLOADS"
echo

last_run_plugins=0
last_run_themes=0
last_run_uploads=0

run_if_due() {
  local key="$1"
  local now
  now="$(date +%s)"

  case "$key" in
    plugins)
      if (( now - last_run_plugins >= DEBOUNCE )); then
        last_run_plugins="$now"
        bash "$BASE_DIR/vsync.sh" plugins || true
      fi
      ;;
    themes)
      if (( now - last_run_themes >= DEBOUNCE )); then
        last_run_themes="$now"
        bash "$BASE_DIR/vsync.sh" themes || true
      fi
      ;;
    uploads)
      if (( now - last_run_uploads >= DEBOUNCE )); then
        last_run_uploads="$now"
        bash "$BASE_DIR/vsync.sh" uploads || true
      fi
      ;;
  esac
}

inotifywait -m -r \
  -e modify,create,delete,move \
  --format '%w%f' \
  "$LOCAL_PLUGINS" "$LOCAL_THEMES" "$LOCAL_UPLOADS" \
| while read -r path; do
    if [[ "$path" == "$LOCAL_PLUGINS"* ]]; then
      echo "🔔 change: plugins → $path"
      run_if_due plugins
    elif [[ "$path" == "$LOCAL_THEMES"* ]]; then
      echo "🔔 change: themes  → $path"
      run_if_due themes
    elif [[ "$path" == "$LOCAL_UPLOADS"* ]]; then
      echo "🔔 change: uploads → $path"
      run_if_due uploads
    fi
  done
