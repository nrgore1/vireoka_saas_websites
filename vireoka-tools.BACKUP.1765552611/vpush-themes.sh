
#!/bin/bash
set -e
source $(dirname "$0")/vconfig.sh

echo "🔄 BACKUP before theme sync..."
$(dirname "$0")/vbackup.sh

echo "⬆️  Syncing THEMES local → server..."
$RSYNC $EXCLUDES \
  "$LOCAL_THEMES/" \
  $REMOTE_USER@$REMOTE_HOST:"$REMOTE_THEMES/" | tee -a "$LOG"

$(dirname "$0")/vpost-sync.sh
echo "✔ Theme push complete."

