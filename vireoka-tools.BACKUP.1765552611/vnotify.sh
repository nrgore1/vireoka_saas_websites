#!/bin/bash
# Vireoka notification helper: desktop + webhook
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$TOOLS_DIR/vconfig.sh"

vnotify() {
  local title="$1"
  local body="$2"
  local level="${3:-info}"  # info|warn|error

  # 1) Webhook (Slack/Discord/etc.)
  if [ -n "$WEBHOOK_URL" ]; then
    curl -s -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "$(printf '{"title":"%s","body":"%s","level":"%s"}' "$title" "$body" "$level")" \
      >/dev/null 2>&1 || true
  fi

  # 2) Linux notify-send
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Vireoka Sync: $title" "$body"
    return 0
  fi

  # 3) WSL → Windows toast via PowerShell
  if grep -qi microsoft /proc/version 2>/dev/null && command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -Command "
      [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null;
      [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > \$null;
      \$template = @'<toast><visual><binding template=\"ToastGeneric\"><text>Vireoka Sync: $title</text><text>$body</text></binding></visual></toast>'@;
      \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;
      \$xml.LoadXml(\$template);
      \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml);
      \$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Vireoka Sync');
      \$notifier.Show(\$toast);
    " >/dev/null 2>&1 || true
    return 0
  fi

  # 4) Fallback: console
  echo "🔔 $title — $body"
}

