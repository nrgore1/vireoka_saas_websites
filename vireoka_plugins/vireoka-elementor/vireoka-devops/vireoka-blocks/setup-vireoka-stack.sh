#!/bin/bash
set -e

echo "Starting Docker stack..."
docker compose up -d

echo "Waiting for WordPress container to be ready (30s)..."
sleep 30

WP_CONTAINER=$(docker ps --filter "ancestor=wordpress:php8.2-apache" --format "{{.ID}}" | head -n 1)

if [ -z "$WP_CONTAINER" ]; then
  echo "Could not find WordPress container. Check docker compose."
  exit 1
fi

echo "Copying Vireoka Elementor templates into container..."
docker cp ../vireoka-elementor "$WP_CONTAINER":/var/www/html/vireoka-elementor

echo "Copying Vireoka Blocks plugin..."
docker cp ../vireoka-blocks "$WP_CONTAINER":/var/www/html/wp-content/plugins/vireoka-blocks

echo "You can now exec into container and run wp-cli to install plugins, activate theme, and import templates."
echo "Example:"
echo "  docker exec -it $WP_CONTAINER bash"
echo "Then inside container:"
echo "  wp plugin install elementor --activate"
echo "  wp plugin activate vireoka-blocks"
