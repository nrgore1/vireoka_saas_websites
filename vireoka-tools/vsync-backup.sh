cat <<'EOF' > vsync-backup.sh
#!/usr/bin/env bash
set -e

source "$(dirname "$0")/vconfig.sh"

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$LOCAL_ROOT/_backups/$STAMP"

mkdir -p "$BACKUP_DIR"

echo "🛡  Creating local backup at $BACKUP_DIR"

rsync -a "$LOCAL_ROOT/wp-content/" "$BACKUP_DIR/wp-content/" >/dev/null

echo "✅ Backup completed"
EOF

chmod +x vsync-backup.sh
