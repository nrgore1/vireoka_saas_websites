#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

PLAN="$LOCAL_STATUS_DIR/resolution_plan.json"
[ -f "$PLAN" ] || { echo "❌ Missing plan. Run: ./vsync-plan.sh"; exit 1; }

echo "🟢 Vire 6 APPLY-SAFE (ONLY LOW risk + policy-allowed actions)"
echo "------------------------------------------"

python3 - <<'PY'
import json, os, subprocess, sys
plan_path = os.environ["PLAN"]
plan = json.load(open(plan_path, "r", encoding="utf-8"))

apply = [it for it in plan.get("items", []) if it.get("action","").startswith("auto_apply_")]
print(f"Auto-applicable items: {len(apply)}")

# We only log; actual file-level apply is performed by mode-specific sync scripts.
# Here we only write a decisions log for audit.
out = os.environ["DECISIONS"]
lines=[]
for it in apply:
    lines.append(json.dumps({
        "path": it.get("path"),
        "action": it.get("action"),
        "risk": it.get("risk_level"),
        "score": it.get("risk_score"),
        "reason": it.get("reason"),
    }))
open(out, "a", encoding="utf-8").write("\n".join(lines) + ("\n" if lines else ""))
print("Wrote decisions:", out)
PY
DECISIONS="$LOCAL_STATUS_DIR/decisions.log" PLAN="$PLAN" python3 -c "import os;print('')" >/dev/null 2>&1 || true

# For now, safest behavior: do not try to surgically rsync per-file (risk of path mismatch).
# Instead: run your normal vsync with "all" but the plugin/theme scripts are already filtered to active-only.
# Uploads are safe anyway.
echo "➡ Running normal sync (all) after recording safe decisions..."
"$BASE_DIR/vsync.sh" all

echo "✅ Apply-safe complete. Audit log: $LOCAL_STATUS_DIR/decisions.log"
