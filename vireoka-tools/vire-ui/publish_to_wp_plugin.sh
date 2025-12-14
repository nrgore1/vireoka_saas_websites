#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$ROOT/../wp-plugin/vire-admin-console"
ASSETS="$PLUGIN_DIR/assets"

echo "✅ Building Vire UI (static export)…"
export NEXT_TELEMETRY_DISABLED=1
npm run build

echo "✅ Publishing dist → WP plugin assets…"
rm -rf "$ASSETS"
mkdir -p "$ASSETS"
cp -R "$ROOT/dist/." "$ASSETS/"

echo "✅ Plugin ready at: $PLUGIN_DIR"
echo "Next: copy this plugin into wp-content/plugins and activate it."
