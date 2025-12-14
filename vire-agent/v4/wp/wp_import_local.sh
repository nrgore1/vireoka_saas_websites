#!/usr/bin/env bash
set -euo pipefail

# Loads vault env if available (not required for local)
bash vire-agent/v4/load_vault.sh || true

WP_CONT="${WP_CONTAINER:-vireoka_wp}"
PAGES_DIR="vire-agent/export/pages"

if ! docker ps --format '{{.Names}}' | grep -q "^${WP_CONT}$"; then
  echo "❌ WordPress container not running: ${WP_CONT}"
  echo "Tip: cd vireoka_local && sudo docker compose up -d"
  exit 1
fi

if [ ! -d "$PAGES_DIR" ]; then
  echo "❌ Missing pages: $PAGES_DIR"
  exit 1
fi

echo "✅ Importing pages into local WP via WP-CLI in container: ${WP_CONT}"

# Ensure wp-cli exists inside container (official image usually doesn't ship it)
# We install wp-cli.phar into /usr/local/bin/wp the first time.
docker exec -it "$WP_CONT" bash -lc '
  if ! command -v wp >/dev/null 2>&1; then
    echo "Installing WP-CLI..."
    curl -sSLo /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    php /tmp/wp-cli.phar --info >/dev/null
    chmod +x /tmp/wp-cli.phar
    mv /tmp/wp-cli.phar /usr/local/bin/wp
  fi
  wp --info | head -n 2
' >/dev/null

for f in "$PAGES_DIR"/*.html; do
  slug="$(basename "$f" .html)"
  title="$(echo "$slug" | sed 's/-/ /g' | awk "{ for (i=1;i<=NF;i++) \$i=toupper(substr(\$i,1,1)) substr(\$i,2); print }")"
  echo "→ Creating/Updating: $title ($slug)"
  # Create if missing; otherwise update content.
  docker exec -i "$WP_CONT" bash -lc "
    ID=\$(wp post list --post_type=page --name='$slug' --field=ID --allow-root 2>/dev/null | head -n 1 || true)
    if [ -z \"\$ID\" ]; then
      wp post create --post_type=page --post_status=publish --post_title=\"$title\" --post_name='$slug' --allow-root --porcelain
    else
      echo \$ID
    fi
  " >/dev/null

  # Update content from file
  docker exec -i "$WP_CONT" bash -lc "
    ID=\$(wp post list --post_type=page --name='$slug' --field=ID --allow-root 2>/dev/null | head -n 1)
    wp post update \"\$ID\" --post_content=\"\$(cat)\" --allow-root >/dev/null
  " < "$f"
done

echo "✅ Local WP pages imported."
echo "🌐 Visit: http://localhost:8085"
