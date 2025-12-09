#!/bin/bash
set -e
# === CONFIG ===
HOST="your-hostinger-ip-or-host"
USER="your-sftp-username"
PASS="your-sftp-password"
REMOTE_PATH="/home/uXXXXXXX/public_html/wp-content/plugins"
echo "Connecting to Hostinger..."
lftp -u "$USER","$PASS" sftp://$HOST << EOF2
lcd $(pwd)
cd $REMOTE_PATH
put vireoka-branding.zip
put vireoka-ui-kit.zip
put vireoka-website-creator.zip
put vireoka-agent-chat.zip
bye
