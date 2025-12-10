#!/bin/bash
# Simple backup script for Vireoka WordPress
# Adjust DB credentials and paths as needed.

SITE_DIR="/var/www/vireoka.com"
BACKUP_DIR="/var/backups/vireoka"
DB_NAME="vireoka_db"
DB_USER="root"
DB_PASS="root"
DATESTAMP=$(date +"%Y%m%d-%H%M")

mkdir -p "$BACKUP_DIR"

echo "Creating database backup..."
mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/db-$DATESTAMP.sql"

echo "Archiving wp-content..."
tar -czf "$BACKUP_DIR/wp-content-$DATESTAMP.tar.gz" -C "$SITE_DIR" wp-content

echo "Backup complete: $DATESTAMP"
