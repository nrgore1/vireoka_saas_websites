#!/bin/bash
# Launch Vireoka Sync Dashboard
set -e
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

# Use your existing venv if you like:
if [ -d "$BASE_DIR/../venv" ]; then
  source "$BASE_DIR/../venv/bin/activate"
fi

echo "🌐 Starting Vireoka Sync Dashboard at http://127.0.0.1:5000 ..."
python3 vsync_dashboard.py
