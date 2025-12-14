#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TOOLS="$ROOT_DIR/../vireoka-tools"
source "$TOOLS/vconfig.sh"

LIVE_BASE="https://vireoka.com"
OUT_DIR="$ROOT_DIR/v5/report"
mkdir -p "$OUT_DIR"

echo "🧪 Verifying LIVE site..."
need_cmd curl

# Basic checks
http_ok "$LIVE_BASE" || die "Live homepage not reachable: $LIVE_BASE"
echo "✅ Live homepage OK: $LIVE_BASE"

# Optional: list key pages via WP-CLI on remote if present
echo "🔎 Checking remote WP-CLI (best effort)..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "command -v wp >/dev/null 2>&1 && cd '$REMOTE_ROOT' && wp option get home || true" || true

# Screenshot report (prefers Playwright; falls back to chromium if available)
python3 "$ROOT_DIR/v5/report/screenshot_report.py" "$LIVE_BASE" "$OUT_DIR" || true

echo "✅ Verify/report done."
echo "📄 Report folder: $OUT_DIR"
