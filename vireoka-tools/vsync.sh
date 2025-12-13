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

# ---- V5.2 EXTENSIONS ----
"$BASE_DIR/vsync-preflight.sh"

if [ "$MODE" = "dry" ]; then
  "$BASE_DIR/vsync-dryrun.sh"
  exit 0
fi

"$BASE_DIR/vsync-backup.sh"
"$BASE_DIR/vsync-conflicts.sh"
"$BASE_DIR/vsync-dashboard.sh"

# ---- V5.3 EXTENSIONS ----
# Render HTML dashboard (local + best-effort remote publish)
"$BASE_DIR/vsync-dashboard-html.sh" || true

# If conflicts exist, generate AI-assisted resolution report (no changes applied)
"$BASE_DIR/vsync-ai-resolve.sh" || true

# =======================
# V5.3 ADD-ONS HOOKS
# =======================
# Load secrets (Vault/.env/env) before doing anything networked
if [ -x "$BASE_DIR/vsync-secrets.sh" ]; then
  "$BASE_DIR/vsync-secrets.sh" || true
fi

# Optional: run CI validate locally by calling:
#   ./vsync-ci-validate.sh
#
# Optional: generate HTML dashboard after each run:
if [ -x "$BASE_DIR/vsync-dashboard-render.sh" ]; then
  "$BASE_DIR/vsync-dashboard-render.sh" || true
fi

# Optional: generate AI-assisted conflict resolution after each run (best-effort)
if [ -x "$BASE_DIR/vsync-ai-resolve.sh" ]; then
  "$BASE_DIR/vsync-ai-resolve.sh" || true
fi
