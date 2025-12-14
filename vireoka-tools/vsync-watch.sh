#!/bin/bash
set -e
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "👀 Vire Watch (event-driven)"
command -v inotifywait >/dev/null 2>&1 || { echo "❌ inotifywait not found. Install: sudo apt-get install -y inotify-tools"; exit 1; }

inotifywait -m -r -e modify,create,delete \
  "$LOCAL_PLUGINS" "$LOCAL_THEMES" "$LOCAL_UPLOADS" |
while read -r path event file; do
  case "$path" in
    *plugins*) bash "$BASE_DIR/vsync.sh" plugins ;;
    *themes*)  bash "$BASE_DIR/vsync.sh" themes ;;
    *uploads*) bash "$BASE_DIR/vsync.sh" uploads ;;
  esac
done
