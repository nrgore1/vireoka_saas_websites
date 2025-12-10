#!/bin/bash
set -euo pipefail

CONFIG_FILE="$(dirname "$0")/vconfig.sh"
source "$CONFIG_FILE"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$REMOTE_WP_ROOT/../backups"
BACKUP_NAME="wp-content-$STAMP.tar.gz"

echo "🛡  Creating remote backup: $BACKUP_NAME"

ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "
  mkdir -p '$BACKUP_DIR' && \
  cd '$REMOTE_WP_ROOT' && \
  tar -czf '$BACKUP_DIR/$BACKUP_NAME' wp-content
"

echo "✅ Backup stored at $BACKUP_DIR/$BACKUP_NAME"
