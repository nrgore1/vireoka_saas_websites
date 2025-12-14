#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
LOCAL_WP_DIR="$ROOT_DIR/../vireoka_local"

WP_CONTAINER="vireoka_wp"
DB_CONTAINER="vireoka_db"

echo "�� Applying Vire V5 to LOCAL WordPress (Docker)"
need_cmd docker

container_running "$WP_CONTAINER" || die "WordPress container not running: $WP_CONTAINER"
container_running "$DB_CONTAINER" || die "DB container not running: $DB_CONTAINER"

ensure_wp_cli_in_container "$WP_CONTAINER"

# Make sure WP is installed (if fresh)
if ! docker exec "$WP_CONTAINER" sh -lc "wp core is-installed --allow-root >/dev/null 2>&1"; then
  echo "🧱 WP not installed in container volume — doing minimal install"
  docker exec "$WP_CONTAINER" sh -lc "wp core install --url=http://localhost:8085 --title='Vireoka Local' --admin_user=admin --admin_password=admin --admin_email=admin@local.test --skip-email --allow-root"
fi

# Activate shared theme (you said: vireoka_core is universal)
docker exec "$WP_CONTAINER" sh -lc "wp theme activate vireoka_core --allow-root" || true

# Import generated pages (Gutenberg HTML as page content)
PAGES_DIR="$ROOT_DIR/v5/outputs/pages"
[ -d "$PAGES_DIR" ] || die "Missing pages dir: $PAGES_DIR (run export first)"

echo "📄 Creating/Updating pages in WP"
for f in "$PAGES_DIR"/*.html; do
  slug="$(basename "$f" .html)"
  title="$(python3 - <<PY
import os
s=os.path.basename("$f").replace(".html","")
print(s.replace("-"," ").title())
PY
)"
  content="$(cat "$f")"

  # If page exists, update; else create
  if docker exec "$WP_CONTAINER" sh -lc "wp post list --post_type=page --name='$slug' --field=ID --allow-root | grep -E '^[0-9]+' >/dev/null 2>&1"; then
    id="$(docker exec "$WP_CONTAINER" sh -lc "wp post list --post_type=page --name='$slug' --field=ID --allow-root | head -n1")"
    docker exec "$WP_CONTAINER" sh -lc "wp post update $id --post_title='$title' --post_content=\"$(printf %s "$content" | sed 's/"/\\"/g')\" --post_status=publish --allow-root"
  else
    docker exec "$WP_CONTAINER" sh -lc "wp post create --post_type=page --post_title='$title' --post_name='$slug' --post_status=publish --post_content=\"$(printf %s "$content" | sed 's/"/\\"/g')\" --allow-root"
  fi
done

# Set Home page
HOME_ID="$(docker exec "$WP_CONTAINER" sh -lc "wp post list --post_type=page --name='home' --field=ID --allow-root | head -n1" || true)"
if [ -n "${HOME_ID:-}" ]; then
  docker exec "$WP_CONTAINER" sh -lc "wp option update show_on_front page --allow-root"
  docker exec "$WP_CONTAINER" sh -lc "wp option update page_on_front $HOME_ID --allow-root"
fi

# Upload assets into wp-content/uploads/vire-v5 so the theme can enqueue if desired
echo "🧱 Publishing V5 assets into uploads/"
docker exec "$WP_CONTAINER" sh -lc "mkdir -p /var/www/html/wp-content/uploads/vire-v5"

docker cp "$ROOT_DIR/v5/wp/vire-v5.css" "$WP_CONTAINER:/var/www/html/wp-content/uploads/vire-v5/vire-v5.css"
docker cp "$ROOT_DIR/v5/wp/neural-canvas.js" "$WP_CONTAINER:/var/www/html/wp-content/uploads/vire-v5/neural-canvas.js"

echo "✅ Local WP ready: http://localhost:8085"
