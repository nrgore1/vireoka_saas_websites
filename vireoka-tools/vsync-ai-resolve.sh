#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/vconfig.sh"

# Ensure conflicts.json exists
if [ ! -f "$LOCAL_CONFLICTS" ]; then
  echo "ℹ️ conflicts.json not found, generating..."
  "$(dirname "$0")/vsync-conflicts.sh"
fi

# Export paths so python can find them reliably
export LOCAL_CONFLICTS
export LOCAL_STATUS_DIR
export SYNC_MODE

python3 "$(dirname "$0")/vsync-ai-resolve.py"
