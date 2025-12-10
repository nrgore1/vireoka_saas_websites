
#!/bin/bash
set -e
source $(dirname "$0")/vconfig.sh

echo "🔄 BACKUP before full wp-content sync..."
$(dirname "$0")/vbackup.sh

echo "⬆️  Syncing FULL wp-content local → server..."
$RSYNC $EXCLUDES \
  "$LOCAL_WP_CONTENT/" \
  $REMOTE_USER@$REMOTE_HOST:"$REMOTE_WP_CONTENT/" | tee -a "$LOG"

$(dirname "$0")/vpost-sync.sh
echo "✔ Full-site push complete."

