#!/usr/bin/env bash
set -euo pipefail

# Reads approval.json in LOCAL_STATUS_DIR, applies plan if action=apply.
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

STATUS_DIR="${LOCAL_STATUS_DIR:-$LOCAL_ROOT/_sync_status}"
APPROVAL="$STATUS_DIR/approval.json"
PLAN="$STATUS_DIR/resolution_plan.json"

if [ ! -f "$APPROVAL" ]; then
  echo "ℹ️ No approval.json found. Nothing to do."
  exit 0
fi

action="$(python3 -c "import json; print(json.load(open('$APPROVAL')).get('action',''))" 2>/dev/null || true)"
if [ -z "$action" ]; then
  echo "⚠️ approval.json exists but no action set."
  exit 1
fi

if [ "$action" = "reject" ]; then
  python3 - <<PY
import json, time
p="$APPROVAL"
d=json.load(open(p))
d["rejected_at"]=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
d["status"]="rejected"
json.dump(d, open(p,"w"), indent=2)
print("✅ Marked rejected:", p)
PY
  exit 0
fi

if [ "$action" != "apply" ]; then
  echo "❌ Unknown action: $action"
  exit 1
fi

if [ ! -f "$PLAN" ]; then
  echo "❌ resolution_plan.json missing: $PLAN"
  exit 1
fi

echo "✅ Approval=apply detected. Applying plan (safe, non-destructive)."

# NOTE: We do NOT auto-merge file contents here.
# We only generate actionable commands for a human/agent to run,
# or you can later wire this to an auto-resolve script with explicit allowlists.
OUT="$STATUS_DIR/apply_instructions.sh"

python3 - <<PY
import json, time
plan=json.load(open("$PLAN"))
items=plan.get("items",[])
lines=[]
lines.append("#!/usr/bin/env bash")
lines.append("set -e")
lines.append('echo "Applying Vire plan instructions..."')
lines.append("")
for it in items:
    path=it.get("path","")
    choice=it.get("choice","manual_review")
    reason=it.get("reason","")
    if choice=="prefer_local":
        lines.append(f'echo "LOCAL WINS: {path}  # {reason}"')
        # your vsync suite already knows how to push; we just suggest:
        lines.append(f'# Suggested: ./vsync.sh all   (or targeted push for: {path})')
    elif choice=="prefer_remote":
        lines.append(f'echo "REMOTE WINS: {path}  # {reason}"')
        lines.append(f'# Suggested: set SYNC_MODE=pull-only then ./vsync.sh all')
    else:
        lines.append(f'echo "MANUAL REVIEW: {path}  # {reason}"')
lines.append("")
open("$OUT","w").write("\\n".join(lines)+"\\n")
PY

chmod +x "$OUT"

python3 - <<PY
import json, time
p="$APPROVAL"
d=json.load(open(p))
d["applied_at"]=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
d["status"]="applied_instructions_generated"
d["instructions"]="apply_instructions.sh"
json.dump(d, open(p,"w"), indent=2)
print("✅ Wrote:", "$OUT")
print("✅ Updated approval.json status.")
PY
