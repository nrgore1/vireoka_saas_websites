#!/usr/bin/env bash
set -e

WP_PATH=${WP_PATH:-/var/www/html}
PAGES="vire-agent/export/pages"

for f in $PAGES/*.html; do
  title=$(basename "$f" .html | sed 's/-/ /g')
  wp post create "$f" --post_title="$title" --post_status=publish --post_type=page --path="$WP_PATH"
done

echo "✅ Deployed pages to WordPress"
