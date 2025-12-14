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
export VIRE_REMOTE_WATCH=1
export VIRE_UPLOADS_FLUSH_INTERVAL=90
export VIRE_GIT_DEBOUNCE_SECONDS=60
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

# -----------------------------
# Vire 6.x speed controls
# -----------------------------
: "${VIRE_ACTIVE_ONLY:=1}"           # 1 => only active plugins/themes by default
: "${VIRE_MANIFEST_CACHE:=1}"        # 1 => enable manifest caching (skip if unchanged)
: "${VIRE_RSYNC_FAST:=1}"            # 1 => add faster rsync flags
: "${VIRE_EVENT_DEBOUNCE_SEC:=2}"    # debounce for event-driven sync

# Extra rsync flags (safe for WP assets)
if [ "${VIRE_RSYNC_FAST}" = "1" ]; then
  # NOTE: keep existing RSYNC_OPTS and append safe speed flags
  RSYNC_OPTS="${RSYNC_OPTS:-} --omit-dir-times --no-perms --no-owner --no-group"
fi

# ==============================
# VIRE PERFORMANCE TUNING
# ==============================

# Manifest cache
MANIFEST_DIR="$LOCAL_STATUS_DIR/manifests"
mkdir -p "$MANIFEST_DIR"

# Fast rsync (WordPress-safe)
RSYNC_OPTS="-az --delete-delay --inplace --no-perms --no-owner --no-group --omit-dir-times"

# Git debounce
GIT_DEBOUNCE_MIN_FILES=3
GIT_DEBOUNCE_SECONDS=120

# Watch / event tuning
VIRE_REMOTE_WATCH="${VIRE_REMOTE_WATCH:-0}"
VIRE_UPLOADS_LOW_PRIORITY=1

# AI prewarm (passive)
VIRE_AI_PREDICT=1

