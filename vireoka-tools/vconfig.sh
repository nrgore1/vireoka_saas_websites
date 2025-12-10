#!/bin/bash

##
# Vireoka Sync Config
# Adjust ONLY if your paths / host change.
##

# ---- LOCAL ROOTS ----
LOCAL_ROOT="/mnt/c/Projects2025/vireoka_website"

# Local mirror of WordPress public_html
LOCAL_WP_ROOT="$LOCAL_ROOT/public_html_local"
LOCAL_WP_CONTENT="$LOCAL_WP_ROOT/wp-content"
LOCAL_PLUGINS="$LOCAL_ROOT/vireoka_plugins"
LOCAL_THEMES="$LOCAL_WP_CONTENT/themes"
LOCAL_UPLOADS="$LOCAL_WP_CONTENT/uploads"

# ---- REMOTE HOST ----
REMOTE_HOST="45.137.159.84"
REMOTE_PORT="65002"
REMOTE_USER="u814009065"

# Remote WordPress root
REMOTE_WP_ROOT="/home/$REMOTE_USER/domains/vireoka.com/public_html"
REMOTE_WP_CONTENT="$REMOTE_WP_ROOT/wp-content"
REMOTE_PLUGINS="$REMOTE_WP_CONTENT/plugins"
REMOTE_THEMES="$REMOTE_WP_CONTENT/themes"
REMOTE_UPLOADS="$REMOTE_WP_CONTENT/uploads"

# ---- RSYNC SETTINGS ----
RSYNC="rsync -avz -e 'ssh -p ${REMOTE_PORT}' --delete"
EXCLUDES=(
  "--exclude=.git/"
  "--exclude=node_modules/"
  "--exclude=vendor/"
  "--exclude=.DS_Store"
  "--exclude=__pycache__/"
  "--exclude=.idea/"
  "--exclude=.vscode/"
)

# Convert EXCLUDES array to flat string
EXCLUDES="${EXCLUDES[*]}"

# ---- STATUS / LOG FILES ----
LOCAL_STATUS_DIR="$LOCAL_ROOT/vireoka-tools/status"
mkdir -p "$LOCAL_STATUS_DIR"

LOCAL_CONFLICTS_JSON="$LOCAL_STATUS_DIR/conflicts_plugins.txt"
LOCAL_SITE_CONFLICTS_JSON="$LOCAL_STATUS_DIR/conflicts_site.txt"

REMOTE_STATUS_DIR="$REMOTE_WP_CONTENT/vireoka-sync"
REMOTE_CONFLICTS_JSON="$REMOTE_STATUS_DIR/conflicts_plugins.txt"
REMOTE_SITE_CONFLICTS_JSON="$REMOTE_STATUS_DIR/conflicts_site.txt"
