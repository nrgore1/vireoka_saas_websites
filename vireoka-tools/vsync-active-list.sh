#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

KIND="${1:?plugins|themes}"
OUT="${2:?output_file}"

REMOTE_CMD="cd \"$REMOTE_ROOT\" && wp --path=\"$REMOTE_ROOT\""

if ! ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "command -v wp >/dev/null 2>&1"; then
  echo "wp-cli not found on remote; returning empty allowlist" > "$OUT"
  exit 0
fi

if [ "$KIND" = "plugins" ]; then
  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$REMOTE_CMD plugin list --status=active --field=name" > "$OUT" || true
elif [ "$KIND" = "themes" ]; then
  # active + parent theme if child theme is active
  ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$REMOTE_CMD theme list --status=active --field=name" > "$OUT" || true
  # attempt to include parent (best effort)
  PARENT="$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$REMOTE_CMD theme list --status=active --format=json" 2>/dev/null | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d[0].get("template","")) if d else print("")' || true)"
  if [ -n "${PARENT:-}" ]; then
    echo "$PARENT" >> "$OUT"
  fi
else
  echo "unknown kind: $KIND" >&2
  exit 2
fi

# normalize + unique
sed -i '/^$/d' "$OUT" 2>/dev/null || true
sort -u "$OUT" -o "$OUT" || true
