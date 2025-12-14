#!/bin/bash
set -euo pipefail

CONFIG_FILE="$(dirname "$0")/vconfig.sh"
source "$CONFIG_FILE"

echo "🧹 Post-sync: clearing caches (if wp-cli available)..."

ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "
  cd '$REMOTE_WP_ROOT' && \
  if command -v wp >/dev/null 2>&1; then
    wp cache flush || true
    wp litespeed-purge all || true
  fi
" || echo "ℹ️ Post-sync wp-cli step skipped or failed (non-fatal)."

echo "✅ Post-sync hook complete."
