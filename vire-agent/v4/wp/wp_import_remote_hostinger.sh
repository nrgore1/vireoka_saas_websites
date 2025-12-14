#!/usr/bin/env bash
set -euo pipefail

# Requires: vconfig.sh (in vireoka-tools) OR env vars:
# REMOTE_HOST REMOTE_USER REMOTE_PORT REMOTE_ROOT
# Also requires remote wp-cli command: wp

PAGES_DIR="vire-agent/export/pages"
[ -d "$PAGES_DIR" ] || { echo "❌ Missing $PAGES_DIR"; exit 1; }

# Try to source vireoka-tools/vconfig.sh if present
if [ -f "vireoka-tools/vconfig.sh" ]; then
  # shellcheck disable=SC1091
  source "vireoka-tools/vconfig.sh"
fi

: "${REMOTE_HOST:?REMOTE_HOST missing}"
: "${REMOTE_USER:?REMOTE_USER missing}"
: "${REMOTE_PORT:?REMOTE_PORT missing}"
: "${REMOTE_ROOT:?REMOTE_ROOT missing}"

echo "✅ Remote import to Hostinger:"
echo "  $REMOTE_USER@$REMOTE_HOST:$REMOTE_ROOT"

# Detect wp-cli on remote
WP_CMD="$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "command -v wp || true")"
[ -n "$WP_CMD" ] || { echo "❌ wp-cli not found on remote. Install WP-CLI or enable it in hosting."; exit 1; }

for f in "$PAGES_DIR"/*.html; do
  slug="$(basename "$f" .html)"
  title="$(echo "$slug" | sed 's/-/ /g' | awk "{ for (i=1;i<=NF;i++) \$i=toupper(substr(\$i,1,1)) substr(\$i,2); print }")"
  echo "→ Remote page: $title ($slug)"

  CONTENT_B64="$(base64 -w0 "$f")"

  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" bash -lc "'
    set -e
    cd \"$REMOTE_ROOT\"
    ID=\$(wp post list --post_type=page --name=\"$slug\" --field=ID 2>/dev/null | head -n 1 || true)
    if [ -z \"\$ID\" ]; then
      ID=\$(wp post create --post_type=page --post_status=publish --post_title=\"$title\" --post_name=\"$slug\" --porcelain)
    fi
    echo \"$CONTENT_B64\" | base64 -d > /tmp/vire_page.html
    wp post update \"\$ID\" --post_content=\"\$(cat /tmp/vire_page.html)\" >/dev/null
    rm -f /tmp/vire_page.html
  '"
done

echo "✅ Remote pages imported to production."
