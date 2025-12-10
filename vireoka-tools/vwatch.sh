#!/bin/bash

WATCH_DIR="$LOCAL_ROOT"

echo "👀 Watching for changes in $WATCH_DIR"

inotifywait -m -r -e modify,delete,create,move "$WATCH_DIR" | while read -r line; do
  echo "⚡ Change detected: $line"
  bash "$(dirname "$0")/vsync.sh" plugins silent
done
