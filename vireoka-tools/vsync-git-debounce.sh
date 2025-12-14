#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

STATE_DIR="${LOCAL_STATUS_DIR:-$BASE_DIR/status}"
mkdir -p "$STATE_DIR"

STAMP="$STATE_DIR/.git_debounce_touch"
META="$STATE_DIR/.git_debounce_meta"
WINDOW="${VIRE_GIT_DEBOUNCE_SECONDS:-45}"

cmd="${1:-help}"
scope="${2:-all}"

touch_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STAMP"
  echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")|$scope" >> "$META"
}

should_commit() {
  [ -f "$STAMP" ] || return 1
  local last epoch now diff
  last="$(cat "$STAMP" 2>/dev/null || true)"
  epoch="$(date -d "$last" +%s 2>/dev/null || echo 0)"
  now="$(date -u +%s)"
  diff=$((now - epoch))
  [ "$diff" -ge "$WINDOW" ]
}

commit_now() {
  # Only commit if repo is dirty
  if git -C "$BASE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git -C "$BASE_DIR" diff --quiet || ! git -C "$BASE_DIR" diff --cached --quiet; then
      bash "$BASE_DIR/vsync-git.sh" || true
    else
      # If not in BASE_DIR, try repo root (one level up typical)
      if git -C "$BASE_DIR/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if ! git -C "$BASE_DIR/.." diff --quiet || ! git -C "$BASE_DIR/.." diff --cached --quiet; then
          (cd "$BASE_DIR/.." && bash "$BASE_DIR/vsync-git.sh") || true
        fi
      fi
    fi
  fi
  rm -f "$STAMP" || true
}

case "$cmd" in
  touch)
    touch_now
    ;;
  flush)
    if should_commit; then
      echo "🧾 Git debounce: committing batched changes (window=${WINDOW}s)"
      commit_now
    else
      echo "🧾 Git debounce: not ready"
    fi
    ;;
  run)
    # background loop mode
    echo "🧾 Git debounce worker running (window=${WINDOW}s)"
    while true; do
      bash "$BASE_DIR/vsync-git-debounce.sh" flush "$scope" || true
      sleep 5
    done
    ;;
  *)
    cat <<HELP
Usage:
  ./vsync-git-debounce.sh touch <scope>
  ./vsync-git-debounce.sh flush
  ./vsync-git-debounce.sh run
Env:
  VIRE_GIT_DEBOUNCE_SECONDS (default 45)
HELP
    ;;
esac
