cat <<'EOF' > vsync-preflight.sh
#!/usr/bin/env bash
set -e

source "$(dirname "$0")/vconfig.sh"

echo "🧭 VIREOKA SYNC PREFLIGHT"
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
EOF

chmod +x vsync-preflight.sh
