#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

MODE="${1:-all}"

echo "🔁  VIREOKA TWO-WAY SYNC v5.0"
echo "=========================================="
echo "Mode: $MODE"
echo

notify() {
  "$BASE_DIR/vsync-notify.sh" "Vireoka Sync ($MODE)" "$1" || true
}

notify "Starting sync..."

case "$MODE" in
  plugins)
    echo "🔌 SYNC: WordPress Plugins"
    "$BASE_DIR/vsync-plugins.sh"
    ;;
  themes)
    echo "🎨 SYNC: WordPress Themes"
    "$BASE_DIR/vsync-themes.sh"
    ;;
  uploads)
    echo "🖼  SYNC: WordPress Uploads"
    "$BASE_DIR/vsync-uploads.sh"
    ;;
  all)
    echo "🔌 SYNC: WordPress Plugins"
    "$BASE_DIR/vsync-plugins.sh"
    echo
    echo "🎨 SYNC: WordPress Themes"
    "$BASE_DIR/vsync-themes.sh"
    echo
    echo "🖼  SYNC: WordPress Uploads"
    "$BASE_DIR/vsync-uploads.sh"
    ;;
  watch)
    "$BASE_DIR/vsync-watch.sh"
    exit 0
    ;;
  *)
    echo "Usage: $0 [plugins|themes|uploads|all|watch]"
    exit 1
    ;;
esac

# Git auto-commit + push
"$BASE_DIR/vsync-git.sh" || true

# Write local status JSON
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
mkdir -p "$(dirname "$LOCAL_STATUS")"

cat > "$LOCAL_STATUS" <<JSON
{
  "last_run": "$TIMESTAMP",
  "mode": "$MODE",
  "sync_mode": "$SYNC_MODE",
  "remote_host": "$REMOTE_HOST",
  "ok": true
}
JSON

# Mirror status to remote (best effort)
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" || true
scp -P "$REMOTE_PORT" "$LOCAL_STATUS" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS" >/dev/null 2>&1 || true

notify "Completed successfully ✅"

echo
echo "✔ Sync complete for mode: $MODE"
