
#!/bin/bash
set -e
source $(dirname "$0")/vconfig.sh

cd "$LOCAL_ROOT"

echo "📌 Staging changes..."
git add .

echo "✏ Commit message:"
read MSG

git commit -m "$MSG"

echo "⬆️ Pushing to origin..."
git push

echo "🚀 Deploying plugins to server..."
$(dirname "$0")/vpush-plugins.sh

echo "✔ Git + deploy complete."

