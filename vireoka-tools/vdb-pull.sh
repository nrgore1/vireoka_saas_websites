#!/usr/bin/env bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

DB_CONTAINER="vireoka_db"

if ! docker ps --format '{{.Names}}' | grep -q "^$DB_CONTAINER$"; then
  echo "❌ Database container '$DB_CONTAINER' not running."
  exit 1
fi

echo "✅ Using DB container: $DB_CONTAINER"

# ------------------------------------------
# Paths
# ------------------------------------------
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
REMOTE_DUMP="/tmp/vireoka_prod_${TIMESTAMP}.sql"
LOCAL_DUMP="$BASE_DIR/vireoka_prod_${TIMESTAMP}.sql"

# ------------------------------------------
# Export PROD DB (Hostinger-safe)
# ------------------------------------------
echo "⬇️  Exporting PROD DB via mysqldump..."

ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "
  cd '$REMOTE_ROOT'

  DB_NAME=\$(php -r \"include 'wp-config.php'; echo DB_NAME;\")
  DB_USER=\$(php -r \"include 'wp-config.php'; echo DB_USER;\")
  DB_PASS=\$(php -r \"include 'wp-config.php'; echo DB_PASSWORD;\")
  DB_HOST=\$(php -r \"include 'wp-config.php'; echo DB_HOST;\")
  
  /usr/bin/mariadb-dump --no-tablespaces -h \"\$DB_HOST\" -u \"\$DB_USER\" -p\"\$DB_PASS\" \"\$DB_NAME\" > \"$REMOTE_DUMP\"
"

# ------------------------------------------
# Download dump
# ------------------------------------------
echo "⬇️  Downloading DB dump..."
scp -P "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DUMP" "$LOCAL_DUMP"
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "rm -f '$REMOTE_DUMP'" || true

# ------------------------------------------
# Import into local DB AS ROOT (FORCED)
# ------------------------------------------
echo "⬇️  Importing into local MySQL as root..."

docker exec -i "$DB_CONTAINER" \
  mysql --protocol=tcp -uroot -proot wordpress < "$LOCAL_DUMP"

# ------------------------------------------
# URL rewrite
# ------------------------------------------
echo "🔁 Rewriting URLs for localhost..."

docker exec -i "$DB_CONTAINER" \
  mysql --protocol=tcp -uroot -proot wordpress <<SQL
UPDATE wp_options
SET option_value='http://localhost:8085'
WHERE option_name IN ('siteurl','home');
SQL

rm -f "$LOCAL_DUMP"

echo
echo "✅ PROD → LOCAL DB sync COMPLETE"
echo "🌐 Open: http://localhost:8085"
