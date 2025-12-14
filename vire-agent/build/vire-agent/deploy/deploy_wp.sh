#!/usr/bin/env bash
set -e

WP_CONTAINER="${WP_CONTAINER:-vireoka_wp}"

for f in export/pages/*.html; do
  TITLE=$(basename "$f" .html | sed 's/-/ /g')
  docker exec -i "$WP_CONTAINER" wp post create \
    --post_type=page \
    --post_title="$TITLE" \
    --post_status=publish \
    --post_content="$(cat "$f")" || true
done

echo "✅ Pages deployed to WordPress"
