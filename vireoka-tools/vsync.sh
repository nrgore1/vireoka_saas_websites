#!/bin/bash
"$BASE_DIR/vsync-ai-predict.sh" || true

set -e
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
"$BASE_DIR/vsync-ai-predict.sh" || true

source "$BASE_DIR/vconfig.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

MODE="${1:-all}"
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

echo "🔁  VIREOKA TWO-WAY SYNC v6.0"
"$BASE_DIR/vsync-ai-predict.sh" || true

echo "=========================================="
"$BASE_DIR/vsync-ai-predict.sh" || true

echo "Mode: $MODE"
"$BASE_DIR/vsync-ai-predict.sh" || true

echo
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

notify() {
"$BASE_DIR/vsync-ai-predict.sh" || true

  "$BASE_DIR/vsync-notify.sh" "Vireoka Sync ($MODE)" "$1" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

}
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

notify "Starting sync..."
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

case "$MODE" in
"$BASE_DIR/vsync-ai-predict.sh" || true

  plugins)
"$BASE_DIR/vsync-ai-predict.sh" || true

    echo "🔌 SYNC: WordPress Plugins"
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-plugins.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true

  themes)
"$BASE_DIR/vsync-ai-predict.sh" || true

    echo "🎨 SYNC: WordPress Themes"
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-themes.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true

  uploads)
"$BASE_DIR/vsync-ai-predict.sh" || true

    echo "🖼  SYNC: WordPress Uploads"
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-uploads.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true

  all)
"$BASE_DIR/vsync-ai-predict.sh" || true

    echo "🔌 SYNC: WordPress Plugins"
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-plugins.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    echo
"$BASE_DIR/vsync-ai-predict.sh" || true

    echo "🎨 SYNC: WordPress Themes"
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-themes.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    echo
"$BASE_DIR/vsync-ai-predict.sh" || true

    echo "🖼  SYNC: WordPress Uploads"
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-uploads.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true

  watch)
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-watch.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    exit 0
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

  # ---------------------------
"$BASE_DIR/vsync-ai-predict.sh" || true

  # Vire 6 modes
"$BASE_DIR/vsync-ai-predict.sh" || true

  # ---------------------------
"$BASE_DIR/vsync-ai-predict.sh" || true

  simulate)
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-preflight.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-simulate.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    exit 0
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true

  plan)
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-preflight.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-conflicts.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-plan.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    exit 0
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true

  explain)
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-preflight.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-conflicts.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-plan.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-explain.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    exit 0
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true

  apply-safe)
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-preflight.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-conflicts.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-plan.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-apply-safe.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    exit 0
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

  dry)
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-preflight.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    "$BASE_DIR/vsync-dryrun.sh"
"$BASE_DIR/vsync-ai-predict.sh" || true

    exit 0
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true

  *)
"$BASE_DIR/vsync-ai-predict.sh" || true

    echo "Usage: $0 [plugins|themes|uploads|all|watch|dry|simulate|plan|explain|apply-safe]"
"$BASE_DIR/vsync-ai-predict.sh" || true

    exit 1
"$BASE_DIR/vsync-ai-predict.sh" || true

    ;;
"$BASE_DIR/vsync-ai-predict.sh" || true

esac
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

# Git auto-commit + push
"$BASE_DIR/vsync-ai-predict.sh" || true

"$BASE_DIR/vsync-git.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

# Write local status JSON
"$BASE_DIR/vsync-ai-predict.sh" || true

TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
"$BASE_DIR/vsync-ai-predict.sh" || true

mkdir -p "$(dirname "$LOCAL_STATUS")"
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

cat > "$LOCAL_STATUS" <<JSON
"$BASE_DIR/vsync-ai-predict.sh" || true

{
"$BASE_DIR/vsync-ai-predict.sh" || true

  "last_run": "$TIMESTAMP",
"$BASE_DIR/vsync-ai-predict.sh" || true

  "mode": "$MODE",
"$BASE_DIR/vsync-ai-predict.sh" || true

  "sync_mode": "$SYNC_MODE",
"$BASE_DIR/vsync-ai-predict.sh" || true

  "remote_host": "$REMOTE_HOST",
"$BASE_DIR/vsync-ai-predict.sh" || true

  "local_root": "$LOCAL_ROOT",
"$BASE_DIR/vsync-ai-predict.sh" || true

  "remote_root": "$REMOTE_ROOT",
"$BASE_DIR/vsync-ai-predict.sh" || true

  "ok": true
"$BASE_DIR/vsync-ai-predict.sh" || true

}
"$BASE_DIR/vsync-ai-predict.sh" || true

JSON
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

# Mirror status to remote (best effort)
"$BASE_DIR/vsync-ai-predict.sh" || true

ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

scp -P "$REMOTE_PORT" "$LOCAL_STATUS" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS" >/dev/null 2>&1 || true
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

notify "Completed successfully ✅"
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

echo
"$BASE_DIR/vsync-ai-predict.sh" || true

echo "✔ Sync complete for mode: $MODE"
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

# ---- Extensions ----
"$BASE_DIR/vsync-ai-predict.sh" || true

"$BASE_DIR/vsync-preflight.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

"$BASE_DIR/vsync-backup.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

"$BASE_DIR/vsync-conflicts.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

"$BASE_DIR/vsync-dashboard.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

"$BASE_DIR/vsync-dashboard-html.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

"$BASE_DIR/vsync-ai-resolve.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true


"$BASE_DIR/vsync-ai-predict.sh" || true

# Vire 6: auto-plan + explain best-effort (won't fail run)
"$BASE_DIR/vsync-ai-predict.sh" || true

"$BASE_DIR/vsync-plan.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

"$BASE_DIR/vsync-explain.sh" || true
"$BASE_DIR/vsync-ai-predict.sh" || true

