#!/usr/bin/env bash
set -euo pipefail

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

die() { echo "❌ $*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

# Find container by exact name
container_running() {
  local name="$1"
  docker ps --format '{{.Names}}' | grep -q "^${name}$"
}

ensure_wp_cli_in_container() {
  local wp_container="$1"
  # wp-cli isn't included in wordpress:php8.2-apache
  if docker exec "$wp_container" sh -lc "command -v wp >/dev/null 2>&1"; then
    return 0
  fi

  echo "🧰 Installing WP-CLI inside container: $wp_container"
  docker exec "$wp_container" sh -lc "php -v >/dev/null 2>&1" || die "PHP missing in container?"
  docker exec "$wp_container" sh -lc "curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
  docker exec "$wp_container" sh -lc "chmod +x /usr/local/bin/wp && wp --info >/dev/null"
}

# Simple curl check
http_ok() {
  local url="$1"
  curl -fsSL -o /dev/null "$url"
}
