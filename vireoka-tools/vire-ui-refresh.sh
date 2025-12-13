#!/usr/bin/env bash
set -e
[ -d "$BASE_DIR/vire-ui" ] || exit 0
cd "$BASE_DIR/vire-ui"
npm install >/dev/null 2>&1 || true
npm run build >/dev/null 2>&1 || true
echo "🧠 Vire UI refreshed"
