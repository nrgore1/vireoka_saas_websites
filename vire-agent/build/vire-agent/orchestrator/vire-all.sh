#!/usr/bin/env bash
set -e

for f in templates/sites/*.json; do
  echo "⚙️ Generating $f"
  ./cli/vire "$f"
done

echo "✅ All product sites generated"
