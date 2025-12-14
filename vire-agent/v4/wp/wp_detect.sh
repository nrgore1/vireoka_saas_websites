#!/usr/bin/env bash
set -euo pipefail
docker ps --format '{{.Names}}' | grep -E '^vireoka_wp$' >/dev/null 2>&1
