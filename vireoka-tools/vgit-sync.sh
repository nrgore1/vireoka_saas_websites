#!/bin/bash
# Vireoka Git auto-commit + push helper
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$TOOLS_DIR/vconfig.sh"

if [ "$GIT_AUTO_PUSH" != "true" ]; then
  echo "⏭  Git auto-push disabled (GIT_AUTO_PUSH=false)."
  exit 0
fi

if [ ! -d "$BASE_DIR/.git" ]; then
  echo "⚠️  No .git repo found in $BASE_DIR – skipping git sync."
  exit 0
fi

cd "$BASE_DIR"

CHANGES=$(git status --porcelain)
if [ -z "$CHANGES" ]; then
  echo "ℹ️  No git changes to commit."
  exit 0
fi

TIMESTAMP="$(date +"%Y-%m-%d %H:%M:%S")"
MSG="Vireoka sync: $TIMESTAMP"

echo "🧩 Git changes detected → committing and pushing..."
git add .

if ! git commit -m "$MSG"; then
  echo "⚠️  Git commit failed (maybe empty commit)."
  exit 0
fi

if git rev-parse --abbrev-ref "$GIT_BRANCH" >/dev/null 2>&1; then
  TARGET_BRANCH="$GIT_BRANCH"
else
  TARGET_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
fi

echo "⬆️  Pushing to branch: $TARGET_BRANCH"
if ! git push origin "$TARGET_BRANCH"; then
  echo "⚠️  git push failed. Please check your remote or credentials."
  exit 0
fi

echo "✅ Git auto-push completed."
