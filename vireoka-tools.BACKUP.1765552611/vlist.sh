#!/bin/bash
echo "🔍 Listing changes (dry run)..."

LOCAL="/mnt/c/Projects2025/vireoka_website/vireoka_plugins/"
REMOTE="u814009065@45.137.159.84:/home/u814009065/domains/vireoka.com/public_html/wp-content/plugins/"

rsync -avz --dry-run --progress \
-e "ssh -p 65002" \
$LOCAL $REMOTE
