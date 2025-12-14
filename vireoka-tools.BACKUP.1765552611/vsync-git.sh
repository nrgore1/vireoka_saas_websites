#!/bin/bash
set -e

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TOOLS_DIR/.." && pwd)"

source "$TOOLS_DIR/vconfig.sh"

if [ "$GIT_AUTO_PUSH" != "true" ]; then
  echo "🔕 Git auto-push disabled (GIT_AUTO_PUSH=false)."
  exit 0
fi

cd "$REPO_ROOT"

if [ ! -d ".git" ]; then
  echo "⚠️  No .git repo at $REPO_ROOT — skipping git sync."
  exit 0
fi

CHANGES=$(git status --porcelain || true)
if [ -z "$CHANGES" ]; then
  echo "✅ No git changes to commit."
  exit 0
fi

echo "🧩 Git changes detected → committing..."
git add vireoka_local vireoka_plugins vireoka-tools || true

MSG="Vireoka sync: $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$MSG" || echo "ℹ️  Nothing staged for commit."

echo "📤 Pushing to origin/$GIT_BRANCH..."
git push origin "$GIT_BRANCH" || echo "⚠️  Git push failed (check remote)."

"$TOOLS_DIR/vsync-notify.sh" "Vireoka Git" "Committed + pushed latest sync." || true
