#!/bin/bash
source $(dirname "$0")/vconfig.sh

echo "⬆️  Pushing local → server..."
echo "-----------------------------------"

$RSYNC \
  $LOCAL_PLUGINS/ \
  $REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/ \
| tee -a "$LOG"

echo "✔ Upload complete."
