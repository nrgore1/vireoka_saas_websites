#!/bin/bash
set -e
echo "===== VIREOKA BOOTSTRAP START ====="
# 1. Zip plugins
echo "== Zipping all plugins =="
rm -f *.zip
zip -r vireoka-branding.zip vireoka-branding
zip -r vireoka-ui-kit.zip vireoka-ui-kit
zip -r vireoka-website-creator.zip vireoka-website-creator
zip -r vireoka-agent-chat.zip vireoka-agent-chat
# 2. Upload plugins to Hostinger
echo "== Uploading plugins to Hostinger =="
bash deploy_plugins_sftp.sh
# 3. Deploy all 4 sites
echo "== Triggering multi-site WordPress generation =="
python3 vireoka_multi_site_deploy.py
echo "===== BOOTSTRAP COMPLETE ====="
