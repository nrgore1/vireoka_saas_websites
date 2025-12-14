#!/usr/bin/env bash
set -e

BIN="./node_modules/.bin/tailwindcss"

if [ ! -x "$BIN" ]; then
  echo "❌ Tailwind CLI not found"
  exit 1
fi

"$BIN" \
  -c tailwind.config.js \
  -i input.css \
  -o ../export/styles.css \
  --minify

echo "✅ Phase-2 CSS compiled successfully (Tailwind v3)"
