
#!/bin/bash
set -e
source $(dirname "$0")/vconfig.sh

echo "🔄 BACKUP before plugin sync..."
$(dirname "$0")/vbackup.sh

echo "⬆️  Syncing PLUGINS local → server..."
$RSYNC $EXCLUDES \
  "$LOCAL_PLUGINS/" \
  $REMOTE_USER@$REMOTE_HOST:"$REMOTE_PLUGINS/" | tee -a "$LOG"

$(dirname "$0")/vpost-sync.sh
echo "✔ Plugin push complete."

