cat <<'EOF' > vsync-conflicts.sh
#!/usr/bin/env bash
set -e

source "$(dirname "$0")/vconfig.sh"

echo "🔍 Detecting conflicts..."

LOCAL_HASH="$(find "$LOCAL_ROOT/wp-content" -type f -exec sha1sum {} \; | sha1sum | cut -d' ' -f1)"
REMOTE_HASH="$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" \
  "find '$REMOTE_ROOT/wp-content' -type f -exec sha1sum {} \; | sha1sum | cut -d' ' -f1" 2>/dev/null || echo unknown)"

mkdir -p "$LOCAL_STATUS_DIR"

cat <<JSON > "$LOCAL_CONFLICTS"
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "local_hash": "$LOCAL_HASH",
  "remote_hash": "$REMOTE_HASH",
  "conflict": $( [ "$LOCAL_HASH" != "$REMOTE_HASH" ] && echo true || echo false )
}
JSON

echo "📄 Conflict report written to $LOCAL_CONFLICTS"
EOF

chmod +x vsync-conflicts.sh
