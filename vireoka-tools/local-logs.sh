#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)/local-docker"
docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" logs -f --tail=200
