#!/bin/bash
set -e

TITLE="${1:-Vireoka Sync}"
MESSAGE="${2:-Done.}"

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$TOOLS_DIR/vconfig.sh" 2>/dev/null || true

# 1) Linux desktop notifications
if command -v notify-send >/dev/null 2>&1; then
  notify-send "$TITLE" "$MESSAGE" || true
fi

# 2) Windows (via WSL) message box (simple but effective)
if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -Command "
  [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null;
  [System.Windows.Forms.MessageBox]::Show('$MESSAGE', '$TITLE');
  " >/dev/null 2>&1 || true
fi

# 3) Webhook / Slack
if [ -n "$WEBHOOK_URL" ]; then
  payload=$(printf '{"text": "*%s* - %s"}' "$TITLE" "$MESSAGE")
  curl -s -X POST -H 'Content-type: application/json' \
    --data "$payload" "$WEBHOOK_URL" >/dev/null 2>&1 || true
fi

# Always log to terminal as fallback
echo "[NOTIFY] $TITLE: $MESSAGE"
