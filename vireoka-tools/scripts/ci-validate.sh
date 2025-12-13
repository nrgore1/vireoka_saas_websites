#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE_DIR"

source "$BASE_DIR/vconfig.sh"

echo "🧪 CI Validate — Vireoka Sync Suite"
echo "----------------------------------"
echo "LOCAL_ROOT=$LOCAL_ROOT"
echo "REMOTE_HOST=$REMOTE_HOST"
echo "REMOTE_USER=$REMOTE_USER"
echo "REMOTE_PORT=$REMOTE_PORT"
echo "----------------------------------"

# Basic sanity
test -d "$LOCAL_ROOT" || (echo "❌ LOCAL_ROOT missing: $LOCAL_ROOT" && exit 1)
test -d "$LOCAL_THEMES" || (echo "❌ LOCAL_THEMES missing: $LOCAL_THEMES" && exit 1)
test -d "$LOCAL_PLUGINS" || (echo "❌ LOCAL_PLUGINS missing: $LOCAL_PLUGINS" && exit 1)

# Ensure scripts are executable
for f in vsync.sh vsync-themes.sh vsync-plugins.sh vsync-uploads.sh vsync-conflicts.sh vsync-dashboard.sh; do
  test -f "$BASE_DIR/$f" || (echo "❌ Missing $f" && exit 1)
done

# Connection check (optional; CI env might not have access)
if [ "${CI_SKIP_REMOTE:-false}" = "true" ]; then
  echo "ℹ️ CI_SKIP_REMOTE=true — skipping SSH/rsync connectivity tests."
  exit 0
fi

echo "🔌 Checking SSH connectivity…"
ssh -o BatchMode=yes -o ConnectTimeout=8 -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "echo ok" >/dev/null

echo "🧪 Running rsync dry-run (themes only)…"
rsync -avzn --itemize-changes -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "$LOCAL_THEMES/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" >/dev/null

echo "✅ CI validation passed"
