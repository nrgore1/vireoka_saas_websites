#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🧭 VIREOKA SYNC PREFLIGHT (V5 – Agentic)"
echo "=================================================="

# --------------------------------------------------
# 0) Basic path validation
# --------------------------------------------------
for p in "$LOCAL_ROOT" "$LOCAL_PLUGINS" "$LOCAL_THEMES" "$LOCAL_UPLOADS"; do
  if [ ! -d "$p" ]; then
    echo "❌ Missing local path: $p"
    exit 1
  fi
done

echo "✅ Local paths validated"

# --------------------------------------------------
# 1) Verify SSH connectivity (fast fail)
# --------------------------------------------------
if ! ssh -p "$REMOTE_PORT" -o BatchMode=yes -o ConnectTimeout=5 \
  "$REMOTE_USER@$REMOTE_HOST" "echo ok" >/dev/null 2>&1; then
  echo "❌ SSH connection failed: $REMOTE_USER@$REMOTE_HOST"
  exit 1
fi

echo "✅ SSH connectivity confirmed"

# --------------------------------------------------
# 2) Detect ACTIVE THEME (remote is source of truth)
# --------------------------------------------------
VIRE_ACTIVE_THEME="$(
  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "
    cd \"$REMOTE_ROOT\" || exit 1
    wp theme list --status=active --field=name 2>/dev/null
  " | head -n1
)"

if [ -z "$VIRE_ACTIVE_THEME" ]; then
  echo "⚠️  Could not detect active theme via WP-CLI"
else
  echo "🎨 Active theme: $VIRE_ACTIVE_THEME"
fi

export VIRE_ACTIVE_THEME

# --------------------------------------------------
# 3) Detect PARENT THEME (if child theme)
# --------------------------------------------------
VIRE_PARENT_THEME="$(
  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "
    cd \"$REMOTE_ROOT\" || exit 1
    wp theme get \"$VIRE_ACTIVE_THEME\" --field=template 2>/dev/null
  "
)"

if [ -n "$VIRE_PARENT_THEME" ] && [ "$VIRE_PARENT_THEME" != "$VIRE_ACTIVE_THEME" ]; then
  echo "🧬 Parent theme: $VIRE_PARENT_THEME"
  export VIRE_PARENT_THEME
else
  unset VIRE_PARENT_THEME
fi

# --------------------------------------------------
# 4) Detect ACTIVE PLUGINS ONLY
# --------------------------------------------------
VIRE_ACTIVE_PLUGINS="$(
  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "
    cd \"$REMOTE_ROOT\" || exit 1
    wp plugin list --status=active --field=name 2>/dev/null
  " | tr '\n' ' '
)"

if [ -z "$VIRE_ACTIVE_PLUGINS" ]; then
  echo "⚠️  No active plugins detected (or wp-cli unavailable)"
else
  echo "🔌 Active plugins:"
  for p in $VIRE_ACTIVE_PLUGINS; do
    echo "  - $p"
  done
fi

export VIRE_ACTIVE_PLUGINS

# --------------------------------------------------
# 5) Remote path validation (best effort)
# --------------------------------------------------
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "
  for d in \"$REMOTE_PLUGINS\" \"$REMOTE_THEMES\" \"$REMOTE_UPLOADS\"; do
    [ -d \"\$d\" ] || echo \"⚠️  Missing remote dir: \$d\"
  done
" || true

# --------------------------------------------------
# 6) Persist preflight snapshot (for dashboards & AI)
# --------------------------------------------------
PREFLIGHT_JSON="$BASE_DIR/.preflight.json"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$PREFLIGHT_JSON" <<JSON
{
  "timestamp": "$TIMESTAMP",
  "remote_host": "$REMOTE_HOST",
  "sync_mode": "$SYNC_MODE",
  "active_theme": "$VIRE_ACTIVE_THEME",
  "parent_theme": "${VIRE_PARENT_THEME:-}",
  "active_plugins": "$(echo "$VIRE_ACTIVE_PLUGINS" | sed 's/"/\\"/g')"
}
JSON

echo "🧠 Prefight snapshot written:"
echo "   $PREFLIGHT_JSON"

# --------------------------------------------------
# 7) Summary
# --------------------------------------------------
echo
echo "------------------------------------------"
echo "Local WP Root:      $LOCAL_ROOT"
echo "Local Plugins:      $LOCAL_PLUGINS"
echo "Local Themes:       $LOCAL_THEMES"
echo "Local Uploads:      $LOCAL_UPLOADS"
echo
echo "Remote WP Root:     $REMOTE_ROOT"
echo "Remote Plugins:     $REMOTE_PLUGINS"
echo "Remote Themes:      $REMOTE_THEMES"
echo "Remote Uploads:     $REMOTE_UPLOADS"
echo
echo "Sync Mode:          $SYNC_MODE"
echo "RSYNC Options:      $RSYNC_OPTS"
echo "------------------------------------------"
echo "✅ Preflight complete"
