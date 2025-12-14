#!/bin/bash
source $(dirname "$0")/vconfig.sh

echo "⬇️  Pulling from server → local..."
echo "-----------------------------------"

$RSYNC \
  $REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/ \
  $LOCAL_PLUGINS/ \
| tee -a "$LOG"

echo "✔ Download complete."
