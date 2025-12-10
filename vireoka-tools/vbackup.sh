#!/bin/bash
# Vireoka backup helper: creates timestamped local snapshots of wp-content
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$TOOLS_DIR/vconfig.sh"

TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
BACKUP_ROOT="$BASE_DIR/backups/$TIMESTAMP"

echo "🧾 Vireoka Backup → $BACKUP_ROOT"

mkdir -p "$BACKUP_ROOT/wp-content"

# Backup plugins, themes, uploads if they exist
if [ -d "$LOCAL_PLUGINS" ]; then
  echo "   📦 Backing up plugins..."
  mkdir -p "$BACKUP_ROOT/wp-content/plugins"
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" \
    "$LOCAL_PLUGINS/" "$BACKUP_ROOT/wp-content/plugins/"
fi

if [ -d "$LOCAL_THEMES" ]; then
  echo "   🎨 Backing up themes..."
  mkdir -p "$BACKUP_ROOT/wp-content/themes"
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" \
    "$LOCAL_THEMES/" "$BACKUP_ROOT/wp-content/themes/"
fi

if [ -d "$LOCAL_UPLOADS" ]; then
  echo "   🖼  Backing up uploads..."
  mkdir -p "$BACKUP_ROOT/wp-content/uploads"
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" \
    "$LOCAL_UPLOADS/" "$BACKUP_ROOT/wp-content/uploads/"
fi

# Small index file
cat > "$BACKUP_ROOT/backup-meta.json" <<META
{
  "timestamp": "$TIMESTAMP",
  "local_root": "$LOCAL_ROOT",
  "wp_content": "$LOCAL_ROOT/wp-content"
}
META

echo "✅ Backup complete: $BACKUP_ROOT"
