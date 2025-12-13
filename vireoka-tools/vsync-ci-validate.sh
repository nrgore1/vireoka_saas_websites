#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🧪 CI Validate: Preflight"
"$BASE_DIR/vsync-preflight.sh" || true

echo "🧪 CI Validate: Required tools"
for t in rsync ssh; do
  command -v "$t" >/dev/null 2>&1 || { echo "❌ Missing tool: $t"; exit 1; }
done

echo "🧪 CI Validate: Local dirs exist"
for d in "$LOCAL_PLUGINS" "$LOCAL_THEMES" "$LOCAL_UPLOADS"; do
  [ -d "$d" ] || { echo "❌ Missing local directory: $d"; exit 1; }
done

echo "🧪 CI Validate: Dry-run rsync (themes/plugins/uploads) — NO CHANGES"
DRY_OPTS="-avzn --delete"
EXC=("${RSYNC_EXCLUDES[@]}")

echo "  • Themes"
rsync $DRY_OPTS -e "$RSYNC_SSH" "${EXC[@]}" "$LOCAL_THEMES/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" >/dev/null

echo "  • Plugins"
rsync $DRY_OPTS -e "$RSYNC_SSH" "${EXC[@]}" "$LOCAL_PLUGINS/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/" >/dev/null

echo "  • Uploads (metadata only; can be large)"
rsync $DRY_OPTS -e "$RSYNC_SSH" "${EXC[@]}" "$LOCAL_UPLOADS/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_UPLOADS/" >/dev/null

echo "✅ CI validation passed"
