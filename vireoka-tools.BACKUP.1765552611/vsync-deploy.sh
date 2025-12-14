#!/bin/bash

source ./vireoka-sync.conf

echo "============================================="
echo " 🚀  VIREOKA SAFE DEPLOY"
echo "============================================="

# Backup on server
BACKUP_DIR="$REMOTE_WP/wp-backups/plugins-$(date +%Y%m%d-%H%M%S)"
echo "📂 Creating remote backup: $BACKUP_DIR"

ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "mkdir -p $BACKUP_DIR"
rsync -avz -e "ssh -p $SSH_PORT" \
    $REMOTE_PLUGINS/ \
    $SSH_USER@$SSH_HOST:$BACKUP_DIR/ \
    $EXCLUDES

echo "📦 Deploying local plugins → server..."
rsync -avz --delete -e "ssh -p $SSH_PORT" \
    $LOCAL_PLUGINS/ \
    $SSH_USER@$SSH_HOST:$REMOTE_PLUGINS/ \
    $EXCLUDES

echo "🔥 Clearing server cache..."
ssh -p $SSH_PORT $SSH_USER@$SSH_HOST "wp cache flush --path=$REMOTE_WP"

echo "============================================="
echo " 🎉 DEPLOY COMPLETE"
echo " Backup stored at: $BACKUP_DIR"
echo "============================================="