#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

STATE_DIR="${LOCAL_STATUS_DIR:-$BASE_DIR/status}"
mkdir -p "$STATE_DIR"

HIST="$STATE_DIR/ai_change_history.log"
OUT="$STATE_DIR/ai_predictions.json"

cmd="${1:-help}"
scope="${2:-}"
path="${3:-}"

record() {
  local s="$1"
  local p="$2"
  echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")|$s|$p" >> "$HIST"
}

predict() {
  # Simple heuristic:
  # - If plugins changed recently → themes likely next (UI adjustments)
  # - If themes changed recently → plugins likely next (support assets)
  # - If uploads changed recently → uploads likely continues (media batch)
  # - Default: plugins + themes

  local last_scopes recent
  last_scopes="$(tail -n 50 "$HIST" 2>/dev/null | cut -d'|' -f2 | tr '\n' ' ' || true)"
  recent="$last_scopes"

  local p=0 t=0 u=0
  grep -q "plugins" <<<"$recent" && p=1 || true
  grep -q "themes"  <<<"$recent" && t=1 || true
  grep -q "uploads" <<<"$recent" && u=1 || true

  local nextA nextB reason
  if [ "$u" -eq 1 ] && [ "$p" -eq 0 ] && [ "$t" -eq 0 ]; then
    nextA="uploads"; nextB="uploads"
    reason="Recent activity dominated by uploads; likely continued media batch."
  elif [ "$p" -eq 1 ] && [ "$t" -eq 0 ]; then
    nextA="themes"; nextB="plugins"
    reason="Plugin changes often trigger minor theme adjustments (UI/CSS), then plugin tweaks."
  elif [ "$t" -eq 1 ] && [ "$p" -eq 0 ]; then
    nextA="plugins"; nextB="themes"
    reason="Theme changes often require plugin asset/config updates next."
  else
    nextA="plugins"; nextB="themes"
    reason="Default: most frequent operational changes are plugins/themes."
  fi

  cat > "$OUT" <<JSON
{
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "prediction": {
    "next_scope_primary": "$nextA",
    "next_scope_secondary": "$nextB",
    "confidence": 0.62,
    "reason": "$(echo "$reason" | sed 's/"/\\"/g')"
  },
  "recent_activity_tail": "$(tail -n 8 "$HIST" 2>/dev/null | sed 's/"/\\"/g' | tr '\n' ';')"
}
JSON

  echo "✅ AI prediction written: $OUT"
}

case "$cmd" in
  record)
    [ -n "$scope" ] || { echo "need scope"; exit 1; }
    record "$scope" "${path:-}"
    predict || true
    ;;
  predict)
    predict
    ;;
  *)
    cat <<'HELP'
Usage:
  ./vire-ai-predict-next.sh record <plugins|themes|uploads> <path>
  ./vire-ai-predict-next.sh predict
Writes:
  $LOCAL_STATUS_DIR/ai_predictions.json
HELP
    ;;
esac
