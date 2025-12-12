#!/usr/bin/env bash
# ==============================
# Vireoka Sync Configuration v5.1
# CANONICAL LOCAL MIRROR FIX
# ==============================

# -------- REMOTE (PRODUCTION) --------
REMOTE_HOST="45.137.159.84"
REMOTE_USER="u814009065"
REMOTE_PORT="65002"

REMOTE_ROOT="/home/u814009065/domains/vireoka.com/public_html"

REMOTE_PLUGINS="$REMOTE_ROOT/wp-content/plugins"
REMOTE_THEMES="$REMOTE_ROOT/wp-content/themes"
REMOTE_UPLOADS="$REMOTE_ROOT/wp-content/uploads"

# -------- LOCAL (CANONICAL MIRROR) --------
# Windows path:
# C:\Projects2025\vireoka_website\vireoka_local\wp
LOCAL_ROOT="/mnt/c/Projects2025/vireoka_website/vireoka_local/wp"

LOCAL_PLUGINS="$LOCAL_ROOT/wp-content/plugins"
LOCAL_THEMES="$LOCAL_ROOT/wp-content/themes"
LOCAL_UPLOADS="$LOCAL_ROOT/wp-content/uploads"

# -------- SYNC STATUS (DASHBOARD) --------
LOCAL_STATUS_DIR="$LOCAL_ROOT/_sync_status"
LOCAL_STATUS="$LOCAL_STATUS_DIR/status.json"
LOCAL_CONFLICTS="$LOCAL_STATUS_DIR/conflicts.json"

REMOTE_STATUS_DIR="$REMOTE_ROOT/_sync_status"
REMOTE_STATUS="$REMOTE_STATUS_DIR/status.json"
REMOTE_CONFLICTS="$REMOTE_STATUS_DIR/conflicts.json"

mkdir -p "$LOCAL_STATUS_DIR"

# -------- RSYNC CONFIG --------
RSYNC_BIN="rsync"
RSYNC_OPTS="-avz --delete"
RSYNC_SSH="ssh -p $REMOTE_PORT"

RSYNC_EXCLUDES=(
  --exclude=".git"
  --exclude="*.zip"
  --exclude="node_modules"
  --exclude="vendor"
)

# -------- SYNC MODE --------
# two-way | pull-only | push-only
SYNC_MODE="two-way"

# -------- ADVANCED --------
WEBHOOK_URL=""

GIT_AUTO_PUSH=true
GIT_BRANCH="main"

# -------- SAFETY CHECK --------
if [ ! -d "$LOCAL_ROOT/wp-content" ]; then
  echo "❌ Local WP mirror not found:"
  echo "   $LOCAL_ROOT/wp-content"
  exit 1
fi
