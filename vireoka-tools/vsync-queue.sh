#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

QUEUE_DIR="${LOCAL_STATUS_DIR:-$BASE_DIR/status}"
mkdir -p "$QUEUE_DIR"
Q_FILE="$QUEUE_DIR/upload_queue.txt"
LOCK="$QUEUE_DIR/upload_queue.lock"

CMD="${1:-help}"

with_lock() {
  exec 9>"$LOCK"
  flock -x 9
  "$@"
  flock -u 9
}

enqueue() {
  local scope="${1:?scope}"
  local item="${2:-}"
  [ "$scope" = "uploads" ] || { echo "only uploads supported"; exit 1; }
  with_lock _enqueue "$item"
}

_enqueue() {
  local item="$1"
  # Store item if present; we don't need it for rsync, but it helps for audit/AI
  if [ -n "$item" ]; then
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")|$item" >> "$Q_FILE"
  else
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")|(unknown)" >> "$Q_FILE"
  fi
  echo "queued"
}

flush() {
  local max="${1:-200}"
  with_lock _flush "$max"
}

_flush() {
  local max="$1"
  if [ ! -f "$Q_FILE" ]; then
    echo "noqueue"
    return 0
  fi

  local count
  count="$(wc -l < "$Q_FILE" | tr -d ' ' || echo 0)"
  if [ "${count:-0}" -eq 0 ]; then
    echo "empty"
    return 0
  fi

  echo "�� Flushing uploads queue (items=$count, max=$max) ..."
  # Perform delta-only uploads sync (your vsync-uploads.sh decides push/pull)
  bash "$BASE_DIR/vsync.sh" uploads silent || true
  bash "$BASE_DIR/vsync-git-debounce.sh" touch uploads || true

  # Trim queue (we treat a flush as "handled")
  if [ "$count" -gt "$max" ]; then
    tail -n +"$((max+1))" "$Q_FILE" > "$Q_FILE.tmp" || true
    mv "$Q_FILE.tmp" "$Q_FILE"
  else
    : > "$Q_FILE"
  fi

  echo "done"
}

case "$CMD" in
  enqueue)
    enqueue "${2:?uploads}" "${3:-}"
    ;;
  flush)
    flush "${2:-200}"
    ;;
  *)
    cat <<'HELP'
Usage:
  ./vsync-queue.sh enqueue uploads <path>
  ./vsync-queue.sh flush [max]
HELP
    ;;
esac
