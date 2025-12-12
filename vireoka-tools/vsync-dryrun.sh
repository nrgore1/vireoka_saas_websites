cat <<'EOF' > vsync-dryrun.sh
#!/usr/bin/env bash
set -e

source "$(dirname "$0")/vconfig.sh"

echo "🧪 DRY RUN — No changes will be made"

rsync -avzn \
  -e "$RSYNC_SSH" \
  "${RSYNC_EXCLUDES[@]}" \
  "$LOCAL_ROOT/wp-content/" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_ROOT/wp-content/"
EOF

chmod +x vsync-dryrun.sh
