#!/bin/bash
#
#  Vireoka Git Deploy v1.0
#  • Optionally commits changes
#  • Pushes to remote Git
#  • Runs plugin + site sync
#

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$BASE_DIR"

echo "📦 Vireoka Git Deploy"
echo "Repo: $BASE_DIR"
echo "---------------------------------------"

echo "🔎 Git status:"
git status

echo "---------------------------------------"
read -rp "Do you want to auto-commit all changes? [y/N]: " REPLY
REPLY=${REPLY:-N}

if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  read -rp "Commit message (default: 'chore: sync viteoka site'): " MSG
  MSG=${MSG:-"chore: sync vireoka site"}

  echo "🧾 Staging all changes..."
  git add -A

  echo "✍️  Committing: $MSG"
  git commit -m "$MSG" || echo "ℹ️ No changes to commit."

  CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
  echo "🚀 Pushing to origin/$CURRENT_BRANCH..."
  git push origin "$CURRENT_BRANCH"
else
  echo "⏭  Skipping commit + push."
fi

echo "---------------------------------------"
echo "🔁 Running plugin + site sync..."

"$TOOLS_DIR/vsync.sh"
"$TOOLS_DIR/vsite-sync.sh"

echo "---------------------------------------"
echo "✅ Git deploy + remote sync complete."
