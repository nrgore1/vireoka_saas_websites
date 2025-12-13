#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

DB_CONTAINER="vireoka_db"

if ! docker ps --format '{{.Names}}' | grep -q "^$DB_CONTAINER$"; then
  echo "❌ Database container '$DB_CONTAINER' not running."
  exit 1
fi

echo "✅ Using DB container: $DB_CONTAINER"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOCAL_DUMP="$BASE_DIR/vireoka_local_${TIMESTAMP}.sql"
REMOTE_DUMP="/tmp/vireoka_local_${TIMESTAMP}.sql"

echo "⬆️  Exporting LOCAL DB from container as root..."
docker exec -i "$DB_CONTAINER" sh -lc "mysqldump -uroot -proot --no-tablespaces wordpress" > "$LOCAL_DUMP"

echo "⬆️  Uploading dump to remote..."
scp -P "$REMOTE_PORT" "$LOCAL_DUMP" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DUMP" >/dev/null

echo "⬆️  Importing dump on remote (Hostinger-safe)..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "
  cd '$REMOTE_ROOT'
  DB_NAME=\$(php -r \"include 'wp-config.php'; echo DB_NAME;\")
  DB_USER=\$(php -r \"include 'wp-config.php'; echo DB_USER;\")
  DB_PASS=\$(php -r \"include 'wp-config.php'; echo DB_PASSWORD;\")
  DB_HOST=\$(php -r \"include 'wp-config.php'; echo DB_HOST;\")
  /usr/bin/mariadb -h \"\$DB_HOST\" -u \"\$DB_USER\" -p\"\$DB_PASS\" \"\$DB_NAME\" < '$REMOTE_DUMP'
  rm -f '$REMOTE_DUMP'
"

rm -f "$LOCAL_DUMP"

echo "✅ LOCAL → PROD DB push COMPLETE"
