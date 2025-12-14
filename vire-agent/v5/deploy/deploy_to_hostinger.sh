#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../bin/common.sh"

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TOOLS="$ROOT_DIR/../vireoka-tools"

[ -d "$TOOLS" ] || die "Missing tools dir: $TOOLS"
[ -f "$TOOLS/vconfig.sh" ] || die "Missing vconfig.sh in: $TOOLS"

echo "🚚 Deploying to Hostinger (files via vsync + DB push)"

# 1) Files (themes/plugins/uploads) using your Vireoka Sync Suite
bash "$TOOLS/vsync.sh" all

# 2) DB push (local → remote)
bash "$TOOLS/vdb-push.sh"

echo "✅ Deploy complete."
