#!/bin/bash
set -e
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🖼 Uploads sync (low priority)"

nice -n 15 "$RSYNC_BIN" $RSYNC_OPTS \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_UPLOADS/" \
  "$LOCAL_UPLOADS/"

echo "✔ Uploads synced"
