#!/bin/bash
set -e

CHANGES=$(git status --porcelain | wc -l | tr -d ' ')

if [ "${CHANGES:-0}" -lt "${GIT_DEBOUNCE_MIN_FILES:-3}" ]; then
  echo "⏸ Git debounce — batching changes ($CHANGES files)"
  exit 0
fi

git add -A
git commit -m "Vire sync $(date -u +"%Y-%m-%dT%H:%M:%SZ")" || true
git push || true
