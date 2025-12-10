
#!/bin/bash
set -e
source $(dirname "$0")/vconfig.sh

echo "🔄 BACKUP before uploads sync..."
$(dirname "$0")/vbackup.sh

echo "⬆️  Syncing UPLOADS local → server..."
$RSYNC \
  "$LOCAL_UPLOADS/" \
  $REMOTE_USER@$REMOTE_HOST:"$REMOTE_UPLOADS/" | tee -a "$LOG"

$(dirname "$0")/vpost-sync.sh
echo "✔ Uploads push complete."

