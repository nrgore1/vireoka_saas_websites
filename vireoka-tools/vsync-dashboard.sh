cat <<'EOF' > vsync-dashboard.sh
#!/usr/bin/env bash
set -e

source "$(dirname "$0")/vconfig.sh"

TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat <<JSON > "$LOCAL_STATUS"
{
  "project": "Vireoka",
  "timestamp": "$TIMESTAMP",
  "mode": "$SYNC_MODE",
  "local_root": "$LOCAL_ROOT",
  "remote_root": "$REMOTE_ROOT",
  "git_auto_push": $GIT_AUTO_PUSH,
  "status": "ok"
}
JSON

echo "📊 Dashboard JSON updated"
EOF

chmod +x vsync-dashboard.sh
