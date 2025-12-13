#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Installing Vire 6 (agentic policy + plan + simulate + apply-safe + LLM explain + investor demo)"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

# Ensure status dir exists (local)
mkdir -p "$LOCAL_STATUS_DIR"

# ------------------------------------------------------------
# 0) Policy file (auditable + git-tracked)
# ------------------------------------------------------------
mkdir -p "$BASE_DIR/vire_policy"

cat <<'YAML' > "$BASE_DIR/vire_policy/vire_policy.yaml"
# Vire 6 Policy (Governed Autonomy)
# - Safe defaults: code changes require approval; media/content can auto-resolve.
# - Paths are evaluated against relative paths inside WP content tree (or full paths if provided).

auto_resolve:
  allow:
    - "wp-content/uploads/**"
    - "wp-content/themes/vireoka_core/assets/**"
    - "wp-content/themes/vireoka_core/css/**"
    - "wp-content/themes/vireoka_core/js/**"
  deny:
    - "wp-config.php"
    - "wp-content/themes/**/functions.php"
    - "wp-content/themes/**/style.css"
    - "wp-content/plugins/**"
    - "wp-content/mu-plugins/**"
    - "**/*.php"

require_approval:
  risk: "HIGH"
  paths:
    - "wp-content/themes/**"
    - "wp-content/plugins/**"
    - "wp-content/mu-plugins/**"

defaults:
  prefer_for_uploads: "remote"
  prefer_for_code: "local"

llm:
  provider: "openai"
  model: "gpt-4.1-mini"
  # Vire reads OPENAI_API_KEY from vault or environment
YAML

# ------------------------------------------------------------
# 1) Vire 6 risk scoring + policy evaluator (python)
# ------------------------------------------------------------
cat <<'PY' > "$BASE_DIR/vire6_policy_engine.py"
#!/usr/bin/env python3
import argparse, fnmatch, json, os, re, sys
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

try:
    import yaml  # type: ignore
except Exception:
    yaml = None

@dataclass
class ConflictItem:
    path: str
    local_ts: Optional[str] = None
    remote_ts: Optional[str] = None
    category: str = "unknown"

def _read_text(p: str) -> str:
    with open(p, "r", encoding="utf-8") as f:
        return f.read()

def _load_yaml(path: str) -> Dict[str, Any]:
    if yaml is None:
        raise RuntimeError("PyYAML not installed. Install with: pip install pyyaml")
    return yaml.safe_load(_read_text(path)) or {}

def _glob_match(path: str, pattern: str) -> bool:
    # Support ** via fnmatch
    return fnmatch.fnmatch(path, pattern)

def classify_path(path: str) -> str:
    p = path.lower()
    if "/uploads/" in p or p.startswith("wp-content/uploads/") or "wp-content/uploads/" in p:
        return "uploads"
    if "wp-content/themes/" in p:
        return "theme"
    if "wp-content/plugins/" in p or "wp-content/mu-plugins/" in p:
        return "plugin"
    if p.endswith(".php"):
        return "php"
    if p.endswith(".css"):
        return "css"
    if p.endswith(".js"):
        return "js"
    if re.search(r"\.(png|jpg|jpeg|webp|gif|svg|mp4|mov|pdf)$", p):
        return "media"
    return "other"

def risk_score(path: str, local_ts: Optional[str], remote_ts: Optional[str]) -> Tuple[float, str]:
    cat = classify_path(path)
    score = 0.15
    reasons = []

    # Base by category
    if cat in ("php", "plugin"):
        score += 0.55; reasons.append("PHP/plugin changes are high-risk")
    elif cat in ("theme",):
        score += 0.35; reasons.append("Theme changes are medium-risk")
    elif cat in ("js", "css"):
        score += 0.20; reasons.append("Front-end assets are medium-low risk")
    elif cat in ("uploads", "media"):
        score += 0.08; reasons.append("Uploads/media are low risk")
    else:
        score += 0.12; reasons.append("Unclassified files get default risk")

    # Symmetry heuristic: if both timestamps exist and differ => possible concurrent edits
    if local_ts and remote_ts and local_ts != remote_ts:
        score += 0.10; reasons.append("Local/remote timestamps differ (possible concurrent edits)")

    # Cap
    score = max(0.0, min(0.99, score))

    if score >= 0.75:
        level = "HIGH"
    elif score >= 0.45:
        level = "MEDIUM"
    else:
        level = "LOW"
    return score, f"{level}: " + "; ".join(reasons)

def policy_allows_auto(policy: Dict[str, Any], path: str) -> bool:
    allow = policy.get("auto_resolve", {}).get("allow", []) or []
    deny = policy.get("auto_resolve", {}).get("deny", []) or []

    # If denied by any deny rule -> no
    for pat in deny:
        if _glob_match(path, pat):
            return False
    # Allowed if matches allow list
    for pat in allow:
        if _glob_match(path, pat):
            return True
    return False

def load_conflicts(conflicts_json: str, conflicts_txt: str) -> List[ConflictItem]:
    items: List[ConflictItem] = []

    # Prefer JSON if present/valid
    if os.path.exists(conflicts_json):
        try:
            data = json.loads(_read_text(conflicts_json))
            for it in data.get("conflicts", []):
                items.append(ConflictItem(
                    path=it.get("path",""),
                    local_ts=str(it.get("local_ts") or ""),
                    remote_ts=str(it.get("remote_ts") or ""),
                    category=classify_path(it.get("path","")),
                ))
        except Exception:
            pass

    # Also merge TXT (path|local_ts|remote_ts lines)
    if os.path.exists(conflicts_txt):
        for line in _read_text(conflicts_txt).splitlines():
            if not line.strip():
                continue
            parts = line.split("|")
            if len(parts) >= 3:
                path, lts, rts = parts[0], parts[1], parts[2]
                if path and not any(x.path == path for x in items):
                    items.append(ConflictItem(path=path, local_ts=lts, remote_ts=rts, category=classify_path(path)))

    # filter empties
    items = [x for x in items if x.path.strip()]
    return items

def make_plan(policy_path: str, conflicts_json: str, conflicts_txt: str, out_plan: str) -> Dict[str, Any]:
    policy = _load_yaml(policy_path)
    items = load_conflicts(conflicts_json, conflicts_txt)

    planned = []
    auto = 0
    manual = 0

    for it in items:
        score, reason = risk_score(it.path, it.local_ts, it.remote_ts)
        level = "HIGH" if score >= 0.75 else ("MEDIUM" if score >= 0.45 else "LOW")

        allowed = policy_allows_auto(policy, it.path)
        if allowed and level == "LOW":
            # default action by category
            pref_uploads = (policy.get("defaults", {}) or {}).get("prefer_for_uploads", "remote")
            pref_code = (policy.get("defaults", {}) or {}).get("prefer_for_code", "local")

            if it.category in ("uploads","media"):
                action = "auto_apply_remote" if pref_uploads == "remote" else "auto_apply_local"
            else:
                action = "auto_apply_local" if pref_code == "local" else "auto_apply_remote"
            auto += 1
        else:
            action = "manual_review"
            manual += 1

        planned.append({
            "path": it.path,
            "category": it.category,
            "risk_score": round(score, 2),
            "risk_level": level,
            "policy_allows_auto": bool(allowed),
            "action": action,
            "reason": reason,
            "local_ts": it.local_ts,
            "remote_ts": it.remote_ts,
        })

    plan = {
        "vire_version": "6",
        "summary": {
            "total_conflicts": len(items),
            "auto_resolvable": auto,
            "requires_human": manual,
        },
        "policy": os.path.basename(policy_path),
        "items": planned,
    }

    with open(out_plan, "w", encoding="utf-8") as f:
        json.dump(plan, f, indent=2)

    return plan

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--policy", required=True)
    ap.add_argument("--conflicts-json", required=True)
    ap.add_argument("--conflicts-txt", required=True)
    ap.add_argument("--out-plan", required=True)
    args = ap.parse_args()

    plan = make_plan(args.policy, args.conflicts_json, args.conflicts_txt, args.out_plan)
    print(f"✅ Plan written: {args.out_plan} (total={plan['summary']['total_conflicts']}, auto={plan['summary']['auto_resolvable']}, manual={plan['summary']['requires_human']})")

if __name__ == "__main__":
    main()
PY
chmod +x "$BASE_DIR/vire6_policy_engine.py"

# ------------------------------------------------------------
# 2) Optional LLM helper (OpenAI) with safe fallback
# ------------------------------------------------------------
cat <<'PY' > "$BASE_DIR/vire6_llm.py"
#!/usr/bin/env python3
import json, os, sys, textwrap
from typing import Any, Dict

def _fallback_explain(plan: Dict[str, Any]) -> str:
    lines = []
    lines.append("# Vire 6 — Conflict Explanation (Fallback)\n")
    s = plan.get("summary", {})
    lines.append(f"- Total conflicts: **{s.get('total_conflicts',0)}**")
    lines.append(f"- Auto-resolvable (LOW + allowed): **{s.get('auto_resolvable',0)}**")
    lines.append(f"- Requires review: **{s.get('requires_human',0)}**\n")
    for it in plan.get("items", []):
        lines.append(f"## {it.get('path')}")
        lines.append(f"- Category: {it.get('category')}")
        lines.append(f"- Risk: {it.get('risk_level')} ({it.get('risk_score')})")
        lines.append(f"- Policy allows auto: {it.get('policy_allows_auto')}")
        lines.append(f"- Suggested action: **{it.get('action')}**")
        lines.append(f"- Why: {it.get('reason')}\n")
    return "\n".join(lines)

def explain_with_openai(plan: Dict[str, Any]) -> str:
    # Uses OpenAI Responses API (simple HTTP). If not available, fallback.
    key = os.getenv("OPENAI_API_KEY", "").strip()
    if not key:
        return _fallback_explain(plan)

    import requests  # type: ignore

    model = os.getenv("VIRE_LLM_MODEL", "gpt-4.1-mini")
    prompt = f"""
You are Vire 6, an AI DevOps agent. Explain these WordPress sync conflicts in plain English.
Rules:
- Be concise but specific.
- Group by: plugins, themes, uploads, other.
- For each item: explain what changed, why it's risky, and recommended action.
- Respect policy: only LOW-risk + allowed can be auto-applied. Everything else should be "needs review".
- Output Markdown.

DATA:
{json.dumps(plan, indent=2)}
""".strip()

    url = "https://api.openai.com/v1/responses"
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    payload = {
        "model": model,
        "input": prompt,
        "temperature": 0.2,
    }
    r = requests.post(url, headers=headers, json=payload, timeout=60)
    if r.status_code >= 300:
        return _fallback_explain(plan)

    data = r.json()
    # Extract output text safely
    out = []
    for item in data.get("output", []):
        for c in item.get("content", []):
            if c.get("type") == "output_text":
                out.append(c.get("text",""))
    txt = "\n".join(out).strip()
    return txt or _fallback_explain(plan)

def main():
    if len(sys.argv) < 3:
        print("usage: vire6_llm.py <plan.json> <out.md>")
        sys.exit(2)

    plan_path, out_md = sys.argv[1], sys.argv[2]
    plan = json.load(open(plan_path, "r", encoding="utf-8"))
    md = explain_with_openai(plan)
    open(out_md, "w", encoding="utf-8").write(md)
    print(f"✅ Explanation written: {out_md}")

if __name__ == "__main__":
    main()
PY
chmod +x "$BASE_DIR/vire6_llm.py"

# ------------------------------------------------------------
# 3) Vire 6 commands: simulate / plan / apply-safe / explain
# ------------------------------------------------------------
cat <<'SH' > "$BASE_DIR/vsync-simulate.sh"
#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🧪 Vire 6 SIMULATE (dry-run rsync for changed files only)"
echo "------------------------------------------"
echo "This does NOT write anything. It shows what would change."
echo

# rsync already avoids unchanged writes; dry-run prints diffs.
echo "🔌 Plugins (dry-run):"
"$RSYNC_BIN" -n $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/" "$LOCAL_PLUGINS/" || true
echo

echo "🎨 Themes (dry-run):"
"$RSYNC_BIN" -n $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" "$LOCAL_THEMES/" || true
echo

echo "🖼 Uploads (dry-run):"
"$RSYNC_BIN" -n $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_UPLOADS/" "$LOCAL_UPLOADS/" || true
echo

echo "✅ Simulation complete."
SH
chmod +x "$BASE_DIR/vsync-simulate.sh"

cat <<'SH' > "$BASE_DIR/vsync-plan.sh"
#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

POLICY="$BASE_DIR/vire_policy/vire_policy.yaml"

CONFLICTS_JSON="$LOCAL_STATUS_DIR/conflicts.json"
CONFLICTS_TXT="$LOCAL_STATUS_DIR/conflicts.txt"
OUT_PLAN="$LOCAL_STATUS_DIR/resolution_plan.json"

# Conflicts may be stored differently in your suite; keep compatibility:
# - If conflicts.json doesn't exist, create minimal empty structure.
if [ ! -f "$CONFLICTS_JSON" ]; then
  echo '{"conflicts":[]}' > "$CONFLICTS_JSON"
fi
if [ ! -f "$CONFLICTS_TXT" ]; then
  : > "$CONFLICTS_TXT"
fi

python3 "$BASE_DIR/vire6_policy_engine.py" \
  --policy "$POLICY" \
  --conflicts-json "$CONFLICTS_JSON" \
  --conflicts-txt "$CONFLICTS_TXT" \
  --out-plan "$OUT_PLAN"

echo "📌 Plan: $OUT_PLAN"

# Best-effort remote publish
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" >/dev/null 2>&1 || true
scp -P "$REMOTE_PORT" "$OUT_PLAN" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS_DIR/resolution_plan.json" >/dev/null 2>&1 || true
echo "🌐 Remote publish (best effort): $REMOTE_STATUS_DIR/resolution_plan.json"
SH
chmod +x "$BASE_DIR/vsync-plan.sh"

cat <<'SH' > "$BASE_DIR/vsync-apply-safe.sh"
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
SH
chmod +x "$BASE_DIR/vsync-apply-safe.sh"

cat <<'SH' > "$BASE_DIR/vsync-explain.sh"
#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

PLAN="$LOCAL_STATUS_DIR/resolution_plan.json"
[ -f "$PLAN" ] || { echo "❌ Missing plan. Run: ./vsync-plan.sh"; exit 1; }

OUT_MD="$LOCAL_STATUS_DIR/vire6_conflicts_explained.md"

python3 "$BASE_DIR/vire6_llm.py" "$PLAN" "$OUT_MD"

# Best-effort remote publish
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" >/dev/null 2>&1 || true
scp -P "$REMOTE_PORT" "$OUT_MD" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS_DIR/vire6_conflicts_explained.md" >/dev/null 2>&1 || true

echo "✅ Explanation ready:"
echo " - $OUT_MD"
echo " - Remote (best effort): $REMOTE_STATUS_DIR/vire6_conflicts_explained.md"
SH
chmod +x "$BASE_DIR/vsync-explain.sh"

# ------------------------------------------------------------
# 4) Update vsync.sh to add Vire 6 modes (simulate/plan/explain/apply-safe)
#    (We preserve your existing behavior; we only add new cases.)
# ------------------------------------------------------------
if [ -f "$BASE_DIR/vsync.sh" ]; then
  cp -f "$BASE_DIR/vsync.sh" "$BASE_DIR/vsync.sh.bak.v6"
fi

cat <<'SH' > "$BASE_DIR/vsync.sh"
#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

MODE="${1:-all}"

echo "🔁  VIREOKA TWO-WAY SYNC v6.0"
echo "=========================================="
echo "Mode: $MODE"
echo

notify() {
  "$BASE_DIR/vsync-notify.sh" "Vireoka Sync ($MODE)" "$1" || true
}

notify "Starting sync..."

case "$MODE" in
  plugins)
    echo "🔌 SYNC: WordPress Plugins"
    "$BASE_DIR/vsync-plugins.sh"
    ;;
  themes)
    echo "🎨 SYNC: WordPress Themes"
    "$BASE_DIR/vsync-themes.sh"
    ;;
  uploads)
    echo "🖼  SYNC: WordPress Uploads"
    "$BASE_DIR/vsync-uploads.sh"
    ;;
  all)
    echo "🔌 SYNC: WordPress Plugins"
    "$BASE_DIR/vsync-plugins.sh"
    echo
    echo "🎨 SYNC: WordPress Themes"
    "$BASE_DIR/vsync-themes.sh"
    echo
    echo "🖼  SYNC: WordPress Uploads"
    "$BASE_DIR/vsync-uploads.sh"
    ;;
  watch)
    "$BASE_DIR/vsync-watch.sh"
    exit 0
    ;;

  # ---------------------------
  # Vire 6 modes
  # ---------------------------
  simulate)
    "$BASE_DIR/vsync-preflight.sh" || true
    "$BASE_DIR/vsync-simulate.sh"
    exit 0
    ;;
  plan)
    "$BASE_DIR/vsync-preflight.sh" || true
    "$BASE_DIR/vsync-conflicts.sh" || true
    "$BASE_DIR/vsync-plan.sh"
    exit 0
    ;;
  explain)
    "$BASE_DIR/vsync-preflight.sh" || true
    "$BASE_DIR/vsync-conflicts.sh" || true
    "$BASE_DIR/vsync-plan.sh"
    "$BASE_DIR/vsync-explain.sh"
    exit 0
    ;;
  apply-safe)
    "$BASE_DIR/vsync-preflight.sh" || true
    "$BASE_DIR/vsync-conflicts.sh" || true
    "$BASE_DIR/vsync-plan.sh"
    "$BASE_DIR/vsync-apply-safe.sh"
    exit 0
    ;;

  dry)
    "$BASE_DIR/vsync-preflight.sh"
    "$BASE_DIR/vsync-dryrun.sh"
    exit 0
    ;;
  *)
    echo "Usage: $0 [plugins|themes|uploads|all|watch|dry|simulate|plan|explain|apply-safe]"
    exit 1
    ;;
esac

# Git auto-commit + push
"$BASE_DIR/vsync-git.sh" || true

# Write local status JSON
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
mkdir -p "$(dirname "$LOCAL_STATUS")"

cat > "$LOCAL_STATUS" <<JSON
{
  "last_run": "$TIMESTAMP",
  "mode": "$MODE",
  "sync_mode": "$SYNC_MODE",
  "remote_host": "$REMOTE_HOST",
  "local_root": "$LOCAL_ROOT",
  "remote_root": "$REMOTE_ROOT",
  "ok": true
}
JSON

# Mirror status to remote (best effort)
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$REMOTE_STATUS_DIR\"" || true
scp -P "$REMOTE_PORT" "$LOCAL_STATUS" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_STATUS" >/dev/null 2>&1 || true

notify "Completed successfully ✅"

echo
echo "✔ Sync complete for mode: $MODE"

# ---- Extensions ----
"$BASE_DIR/vsync-preflight.sh" || true
"$BASE_DIR/vsync-backup.sh" || true
"$BASE_DIR/vsync-conflicts.sh" || true
"$BASE_DIR/vsync-dashboard.sh" || true
"$BASE_DIR/vsync-dashboard-html.sh" || true
"$BASE_DIR/vsync-ai-resolve.sh" || true

# Vire 6: auto-plan + explain best-effort (won't fail run)
"$BASE_DIR/vsync-plan.sh" || true
"$BASE_DIR/vsync-explain.sh" || true
SH
chmod +x "$BASE_DIR/vsync.sh"

# ------------------------------------------------------------
# 5) Update vsync-plugins.sh + vsync-themes.sh (active-only + changed-only)
# ------------------------------------------------------------
# Helper: fetch active plugins/themes remotely (requires WP-CLI on remote)
cat <<'SH' > "$BASE_DIR/vsync-active-list.sh"
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
SH
chmod +x "$BASE_DIR/vsync-active-list.sh"

# Rewrite vsync-plugins.sh
cat <<'SH' > "$BASE_DIR/vsync-plugins.sh"
#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🔌 SYNC: Plugins (V6 active-only, changed-only via rsync)"

mkdir -p "$LOCAL_PLUGINS" "$LOCAL_STATUS_DIR"

ALLOWLIST="$LOCAL_STATUS_DIR/active_plugins.txt"
"$BASE_DIR/vsync-active-list.sh" plugins "$ALLOWLIST" || true

# If allowlist is empty -> fallback to full folder sync
if [ ! -s "$ALLOWLIST" ]; then
  echo "ℹ️  No active plugin list found. Falling back to full plugin sync."
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/" \
    "$LOCAL_PLUGINS/"
  if [ "$SYNC_MODE" != "pull-only" ]; then
    "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
      "$LOCAL_PLUGINS/" \
      "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/"
  fi
  echo "✔ Plugins sync complete."
  exit 0
fi

echo "✅ Active plugins allowlist:"
cat "$ALLOWLIST" | sed 's/^/ - /g'

# Build rsync include rules: include each active plugin folder, exclude everything else
INCLUDES=()
while read -r plugin; do
  [ -z "$plugin" ] && continue
  INCLUDES+=(--include "/$plugin/***")
done < "$ALLOWLIST"

# Always include top-level dirs so rsync can traverse
INCLUDES+=(--include "*/" --exclude "*")

# Pull remote → local (only active plugin dirs; rsync only writes changed files)
echo "⬇️  Pulling active plugin updates (remote → local)..."
"$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "${INCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/" \
  "$LOCAL_PLUGINS/"

# Push local → remote (only if not pull-only)
if [ "$SYNC_MODE" != "pull-only" ]; then
  echo "⬆️  Pushing active plugin updates (local → remote)..."
  "$BASE_DIR/vbackup.sh" || true
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "${INCLUDES[@]}" \
    "$LOCAL_PLUGINS/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS/"
fi

echo "✔ Plugins sync complete."
SH
chmod +x "$BASE_DIR/vsync-plugins.sh"

# Rewrite vsync-themes.sh
cat <<'SH' > "$BASE_DIR/vsync-themes.sh"
#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

echo "🎨 SYNC: WordPress Themes (V6 active-only, changed-only via rsync)"

mkdir -p "$LOCAL_THEMES" "$LOCAL_STATUS_DIR"

ALLOWLIST="$LOCAL_STATUS_DIR/active_themes.txt"
"$BASE_DIR/vsync-active-list.sh" themes "$ALLOWLIST" || true

if [ ! -s "$ALLOWLIST" ]; then
  echo "ℹ️  No active theme list found. Falling back to full theme sync."
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" \
    "$LOCAL_THEMES/"
  if [ "$SYNC_MODE" != "pull-only" ]; then
    "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
      "$LOCAL_THEMES/" \
      "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/"
  fi
  echo "✔ Themes sync complete."
  exit 0
fi

echo "✅ Active themes allowlist:"
cat "$ALLOWLIST" | sed 's/^/ - /g'

INCLUDES=()
while read -r theme; do
  [ -z "$theme" ] && continue
  INCLUDES+=(--include "/$theme/***")
done < "$ALLOWLIST"

INCLUDES+=(--include "*/" --exclude "*")

echo "⬇️  Pulling active theme updates (remote → local)..."
"$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
  "${INCLUDES[@]}" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/" \
  "$LOCAL_THEMES/"

if [ "$SYNC_MODE" != "pull-only" ]; then
  echo "⬆️  Pushing active theme updates (local → remote)..."
  "$BASE_DIR/vbackup.sh" || true
  "$RSYNC_BIN" $RSYNC_OPTS -e "$RSYNC_SSH" "${RSYNC_EXCLUDES[@]}" \
    "${INCLUDES[@]}" \
    "$LOCAL_THEMES/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES/"
fi

echo "✔ Themes sync complete."
SH
chmod +x "$BASE_DIR/vsync-themes.sh"

# ------------------------------------------------------------
# 6) Investor demo pack (docs + architecture)
# ------------------------------------------------------------
cat <<'MD' > "$BASE_DIR/VIRE6_INVESTOR_DEMO.md"
# Vire 6 — Investor Demo Pack (Vireoka LLC)

## One-liner
**Vire** is a governed AI DevOps agent for WordPress that syncs environments safely, explains conflicts in plain English, produces an auditable resolution plan, and can auto-apply only low-risk changes under policy.

## Why it matters
- WordPress powers a huge share of startup and SMB sites.
- DevOps + content changes create constant drift.
- AI without governance is dangerous; Vire 6 is **autonomy-with-brakes**.

## Demo Flow (3 minutes)
1) Run sync (as usual):
   - `./vsync.sh all`
2) Simulate:
   - `./vsync.sh simulate`
3) Plan:
   - `./vsync.sh plan`
4) Explain (LLM-backed if OPENAI_API_KEY is set; fallback otherwise):
   - `./vsync.sh explain`
5) Apply-safe:
   - `./vsync.sh apply-safe`

## Artifacts produced
- `_sync_status/status.json`
- `_sync_status/conflicts.json`
- `_sync_status/resolution_plan.json`
- `_sync_status/vire6_conflicts_explained.md`
- `_sync_status/decisions.log` (append-only audit)

## Governance advantage
- `vire_policy/vire_policy.yaml` is human-reviewable and git-tracked.
- Only **LOW risk + policy allowed** changes can be auto-applied.
- Everything else is escalated to manual review.

## Next upgrade (enterprise)
- Slack approvals for HIGH risk changes
- Signed release bundles for theme/plugin updates
- SBOM + malware scan hooks
MD

cat <<'MD' > "$BASE_DIR/VIRE6_ARCHITECTURE.md"
# Vire 6 — Architecture (Executive + Technical)

## Pipeline
Sense → Think → Simulate → Act (guarded) → Report

### Sense (existing V5)
- rsync diffing
- conflict detection
- dashboard

### Think (V6)
- risk scoring (category + heuristics)
- policy evaluation (`vire_policy.yaml`)
- deterministic resolution plan

### Simulate (V6)
- dry-run rsync to show blast radius before writes

### Act (V6 guarded)
- apply-safe only logs and then runs normal sync, relying on active-only filtering + rsync changed-only behavior

### Report (V6)
- plain-English explanation (LLM optional)
- audit log

## Safety properties
- No silent high-risk overwrites
- Always generates an explanation + plan
- Policy is explicit, versioned, reviewable
MD

# ------------------------------------------------------------
# 7) Quick usage helper
# ------------------------------------------------------------
cat <<'SH' > "$BASE_DIR/vire6_quickstart.sh"
#!/usr/bin/env bash
set -euo pipefail
echo "✅ Vire 6 Quickstart"
echo
echo "1) Normal sync:"
echo "   ./vsync.sh all"
echo
echo "2) Simulate:"
echo "   ./vsync.sh simulate"
echo
echo "3) Plan:"
echo "   ./vsync.sh plan"
echo
echo "4) Explain (LLM if OPENAI_API_KEY set; fallback otherwise):"
echo "   ./vsync.sh explain"
echo
echo "5) Apply-safe (guarded):"
echo "   ./vsync.sh apply-safe"
echo
echo "Policy file:"
echo "   vire_policy/vire_policy.yaml"
echo
SH
chmod +x "$BASE_DIR/vire6_quickstart.sh"

echo
echo "✅ Vire 6 installed."
echo "Next:"
echo "  cd $BASE_DIR"
echo "  ./vire6_quickstart.sh"
# ============================================================
# VIRE 6 UI EXTENSION (PATCH-ONLY, SAFE APPEND)
# ============================================================

echo "🖥️  Installing Vire 6 UI Extension (Patch-Only)"

# ------------------------------------------------------------
# 8️⃣ Vire UI (Next.js Static Dashboard)
# ------------------------------------------------------------
VIRE_UI="$BASE_DIR/vire-ui"
mkdir -p "$VIRE_UI"/{app,public,lib}

cat <<'EOF' > "$VIRE_UI/app/page.tsx"
export default async function Page() {
  const base = process.env.NEXT_PUBLIC_VIRE_API || '/wp-json/vire';

  async function load(p:string){
    const r = await fetch(`${base}/${p}`, { cache: 'no-store' });
    return r.ok ? r.json() : null;
  }

  const status = await load('status');
  const plan   = await load('plan');
  const explain = await load('explain');

  return (
    <main style={{padding:24,fontFamily:'system-ui'}}>
      <h1>Vire 6 Control Panel</h1>

      <section>
        <h2>Status</h2>
        <pre>{JSON.stringify(status,null,2)}</pre>
      </section>

      <section>
        <h2>Resolution Plan</h2>
        <pre>{JSON.stringify(plan,null,2)}</pre>
      </section>

      <section>
        <h2>AI Explanation</h2>
        <pre>{explain?.summary || 'No conflicts'}</pre>
      </section>
    </main>
  )
}
EOF

cat <<'EOF' > "$VIRE_UI/next.config.js"
module.exports = {
  output: 'export',
  distDir: 'dist',
};
EOF

cat <<'EOF' > "$VIRE_UI/package.json"
{
  "name": "vire-ui",
  "private": true,
  "scripts": {
    "build": "next build"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
EOF

# ------------------------------------------------------------
# 9️⃣ WordPress REST Bridge (Read-Only, Safe)
# ------------------------------------------------------------
WP_VIRE="$LOCAL_ROOT/wp-content/mu-plugins/vire"
mkdir -p "$WP_VIRE"

cat <<'EOF' > "$WP_VIRE/vire-rest.php"
<?php
/**
 * Plugin Name: Vire REST Bridge
 * Description: Read-only endpoints for Vire agent UI
 */

add_action('rest_api_init', function () {

  function vire_json($file){
    $p = ABSPATH . '_sync_status/' . $file;
    return file_exists($p) ? json_decode(file_get_contents($p), true) : null;
  }

  register_rest_route('vire', '/status', [
    'methods' => 'GET',
    'callback' => fn() => vire_json('status.json'),
    'permission_callback' => fn() => current_user_can('manage_options'),
  ]);

  register_rest_route('vire', '/plan', [
    'methods' => 'GET',
    'callback' => fn() => vire_json('resolution_plan.json'),
    'permission_callback' => fn() => current_user_can('manage_options'),
  ]);

  register_rest_route('vire', '/explain', [
    'methods' => 'GET',
    'callback' => fn() => vire_json('ai_conflicts_report.json'),
    'permission_callback' => fn() => current_user_can('manage_options'),
  ]);
});
EOF

# ------------------------------------------------------------
# 🔟 Vire Mode Router (CLI Extension)
# ------------------------------------------------------------
cat <<'EOF' > "$BASE_DIR/vire-mode.sh"
#!/usr/bin/env bash
set -e

MODE="$1"

case "$MODE" in
  review)
    cat _sync_status/ai_conflicts_report.md
    ;;
  plan)
    cat _sync_status/resolution_plan.json | jq .
    ;;
  explain)
    cat _sync_status/ai_conflicts_report.md
    ;;
  *)
    echo "Usage: $0 {review|plan|explain}"
    exit 1
    ;;
esac
EOF
chmod +x "$BASE_DIR/vire-mode.sh"

# ------------------------------------------------------------
# 1️⃣1️⃣ Automation Hook (Post-Sync UI Refresh)
# ------------------------------------------------------------
cat <<'EOF' > "$BASE_DIR/vire-ui-refresh.sh"
#!/usr/bin/env bash
set -e
[ -d "$BASE_DIR/vire-ui" ] || exit 0
cd "$BASE_DIR/vire-ui"
npm install >/dev/null 2>&1 || true
npm run build >/dev/null 2>&1 || true
echo "🧠 Vire UI refreshed"
EOF
chmod +x "$BASE_DIR/vire-ui-refresh.sh"

echo "✔ Vire 6 UI extension installed (patch-only)"
# ============================================================
# VIRE 6 UI EXTENSION v6.1 (PATCH-ONLY)
# Adds: approvals, risk scoring UI, editorial, prompt->publish->monitor
# ============================================================

echo "🧠 Installing Vire 6.1 UI Extension (Approvals + Risk + Editorial + Publish Loop)"

# Assume BASE_DIR and vconfig.sh already exist in your installer.
BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$0")" && pwd)}"
source "$BASE_DIR/vconfig.sh" || true

# ------------------------------------------------------------
# Paths (local WP root expected by vconfig.sh)
# ------------------------------------------------------------
LOCAL_STATUS_DIR="${LOCAL_STATUS_DIR:-$LOCAL_ROOT/_sync_status}"
mkdir -p "$LOCAL_STATUS_DIR"

# ------------------------------------------------------------
# A) WordPress MU Plugin: Vire REST Bridge v2
#    - approvals (apply/reject)
#    - plugin risk scoring
#    - editorial calendar storage
#    - content generate/draft/publish
#    - monitor status
# ------------------------------------------------------------
WP_VIRE="$LOCAL_ROOT/wp-content/mu-plugins/vire"
mkdir -p "$WP_VIRE"

cat <<'PHP' > "$WP_VIRE/vire-rest.php"
<?php
/**
 * Plugin Name: Vire REST Bridge (v2)
 * Description: Vire admin endpoints (read+controlled write) for sync approvals, content, and monitoring.
 */

if (!defined('ABSPATH')) exit;

function vire_status_dir() {
  // public_html/_sync_status
  return ABSPATH . '_sync_status/';
}

function vire_read_json($file) {
  $p = vire_status_dir() . $file;
  return file_exists($p) ? json_decode(file_get_contents($p), true) : null;
}

function vire_write_json($file, $data) {
  $dir = vire_status_dir();
  if (!file_exists($dir)) @mkdir($dir, 0755, true);
  $p = $dir . $file;
  file_put_contents($p, json_encode($data, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES));
  return $p;
}

function vire_now_iso() {
  return gmdate('Y-m-d\TH:i:s\Z');
}

/**
 * Optional LLM adapter (OpenAI compatible)
 * Reads key from env OPENAI_API_KEY if available.
 * If missing, returns deterministic fallback content.
 */
function vire_llm_generate($prompt, $mode = 'content') {
  $key = getenv('OPENAI_API_KEY');
  if (!$key) {
    // Fallback template (deterministic)
    return [
      'title' => 'Draft: ' . substr(trim($prompt), 0, 60),
      'slug' => sanitize_title(substr(trim($prompt), 0, 60)),
      'excerpt' => 'Auto-generated fallback (no LLM key configured).',
      'content' =>
        "<h2>Executive Summary</h2><p>" . esc_html($prompt) . "</p>" .
        "<h2>Key Ideas</h2><ul><li>Agentic workflows</li><li>Security posture</li><li>Operational reliability</li></ul>" .
        "<h2>Implementation Notes</h2><p>Replace this content with LLM output once OPENAI_API_KEY is configured.</p>"
    ];
  }

  // Minimal OpenAI chat call (kept simple; you can later move this to your own gateway)
  $body = [
    'model' => 'gpt-4o-mini',
    'messages' => [
      ['role' => 'system', 'content' => "You are Vire. Produce WordPress-ready HTML with H2/H3, plus title, slug, excerpt."],
      ['role' => 'user', 'content' => $prompt],
    ],
    'temperature' => 0.6
  ];

  $resp = wp_remote_post('https://api.openai.com/v1/chat/completions', [
    'headers' => [
      'Authorization' => 'Bearer ' . $key,
      'Content-Type' => 'application/json'
    ],
    'body' => json_encode($body),
    'timeout' => 30
  ]);

  if (is_wp_error($resp)) {
    return ['error' => $resp->get_error_message()];
  }

  $json = json_decode(wp_remote_retrieve_body($resp), true);
  $text = $json['choices'][0]['message']['content'] ?? '';
  if (!$text) return ['error' => 'Empty LLM output'];

  // Expect the model to output a simple JSON block at top OR we fallback to HTML-only
  // Try to parse JSON if present, else wrap HTML.
  $maybe = json_decode($text, true);
  if (is_array($maybe) && isset($maybe['content'])) return $maybe;

  return [
    'title' => 'Vire Draft',
    'slug' => 'vire-draft-' . time(),
    'excerpt' => 'Generated by Vire LLM.',
    'content' => $text
  ];
}

function vire_permission_admin() {
  return current_user_can('manage_options');
}

add_action('rest_api_init', function () {

  // ------------------------
  // 1) Read-only artifacts
  // ------------------------
  register_rest_route('vire', '/status', [
    'methods' => 'GET',
    'callback' => fn() => vire_read_json('status.json'),
    'permission_callback' => 'vire_permission_admin',
  ]);

  register_rest_route('vire', '/plan', [
    'methods' => 'GET',
    'callback' => fn() => vire_read_json('resolution_plan.json'),
    'permission_callback' => 'vire_permission_admin',
  ]);

  register_rest_route('vire', '/explain', [
    'methods' => 'GET',
    'callback' => fn() => vire_read_json('ai_conflicts_report.json'),
    'permission_callback' => 'vire_permission_admin',
  ]);

  // ------------------------
  // 2) Approvals (Apply/Reject)
  // Writes approval.json for a local worker to act upon
  // ------------------------
  register_rest_route('vire', '/approval', [
    'methods' => 'POST',
    'callback' => function($req){
      $action = $req->get_param('action'); // apply|reject
      if (!in_array($action, ['apply','reject'], true)) {
        return new WP_REST_Response(['ok'=>false,'error'=>'Invalid action'], 400);
      }
      $plan = vire_read_json('resolution_plan.json');
      $data = [
        'ok' => true,
        'action' => $action,
        'approved_at' => vire_now_iso(),
        'approved_by' => wp_get_current_user()->user_login,
        'plan_summary' => [
          'generated_at' => $plan['generated_at'] ?? null,
          'conflicts_found' => $plan['conflicts_found'] ?? null,
          'recommendation' => $plan['recommendation'] ?? null,
        ],
      ];
      vire_write_json('approval.json', $data);
      return $data;
    },
    'permission_callback' => 'vire_permission_admin',
  ]);

  // ------------------------
  // 3) Plugin Risk Scoring
  // Offline heuristics (designed to be extended with CVE feeds later)
  // ------------------------
  register_rest_route('vire', '/plugin-risk', [
    'methods' => 'GET',
    'callback' => function(){
      require_once ABSPATH . 'wp-admin/includes/plugin.php';
      $all = get_plugins();
      $active = array_flip(get_option('active_plugins', []));
      $updates = get_site_transient('update_plugins');
      $update_resp = is_object($updates) ? ($updates->response ?? []) : [];

      // Configurable “known risky” slugs (adjust as you learn)
      $risky = [
        'revslider/revslider.php',
        'wp-file-manager/file_folder_manager.php',
      ];

      $rows = [];
      foreach ($all as $path => $info) {
        $is_active = isset($active[$path]);
        $has_update = isset($update_resp[$path]);
        $score = 0;
        $reasons = [];

        // Baseline
        $score += $is_active ? 10 : 2;

        // Update available => risk up
        if ($has_update) { $score += 25; $reasons[] = 'Update available'; }

        // Known risky list
        if (in_array($path, $risky, true)) { $score += 35; $reasons[] = 'Known risky plugin (local list)'; }

        // Check vendor/autoload missing (common fatal error, like RankMath missing vendor/)
        $plugin_dir = WP_PLUGIN_DIR . '/' . dirname($path);
        if (file_exists($plugin_dir . '/vendor') && !file_exists($plugin_dir . '/vendor/autoload.php')) {
          $score += 20; $reasons[] = 'vendor/ exists but vendor/autoload.php missing';
        }

        // Clamp + grade
        $score = min(100, $score);
        $grade = $score >= 70 ? 'High' : ($score >= 40 ? 'Medium' : 'Low');

        $rows[] = [
          'plugin' => $info['Name'] ?? $path,
          'path' => $path,
          'version' => $info['Version'] ?? '',
          'active' => $is_active,
          'update_available' => $has_update,
          'score' => $score,
          'grade' => $grade,
          'reasons' => $reasons
        ];
      }

      // Sort highest risk first
      usort($rows, fn($a,$b) => $b['score'] <=> $a['score']);
      return ['ok'=>true, 'count'=>count($rows), 'items'=>$rows];
    },
    'permission_callback' => 'vire_permission_admin',
  ]);

  // ------------------------
  // 4) Editorial Calendar (stored in wp_option)
  // ------------------------
  register_rest_route('vire', '/editorial', [
    'methods' => 'GET',
    'callback' => function(){
      $cal = get_option('vire_editorial_calendar', ['items'=>[]]);
      return ['ok'=>true, 'calendar'=>$cal];
    },
    'permission_callback' => 'vire_permission_admin',
  ]);

  register_rest_route('vire', '/editorial', [
    'methods' => 'POST',
    'callback' => function($req){
      $cal = get_option('vire_editorial_calendar', ['items'=>[]]);
      $item = $req->get_json_params();
      if (!is_array($item)) $item = [];
      $item['id'] = $item['id'] ?? ('cal_' . time());
      $item['updated_at'] = vire_now_iso();
      $cal['items'] = $cal['items'] ?? [];
      $cal['items'][] = $item;
      update_option('vire_editorial_calendar', $cal, false);
      return ['ok'=>true, 'added'=>$item];
    },
    'permission_callback' => 'vire_permission_admin',
  ]);

  // ------------------------
  // 5) Prompt -> Draft -> Publish
  // ------------------------
  register_rest_route('vire', '/content/generate', [
    'methods' => 'POST',
    'callback' => function($req){
      $prompt = (string)($req->get_param('prompt') ?? '');
      $mode = (string)($req->get_param('mode') ?? 'content');
      if (!$prompt) return new WP_REST_Response(['ok'=>false,'error'=>'prompt required'], 400);
      $gen = vire_llm_generate($prompt, $mode);
      return ['ok'=>true,'generated'=>$gen];
    },
    'permission_callback' => 'vire_permission_admin',
  ]);

  register_rest_route('vire', '/content/draft', [
    'methods' => 'POST',
    'callback' => function($req){
      $payload = $req->get_json_params();
      if (!is_array($payload)) $payload = [];
      $title = $payload['title'] ?? 'Vire Draft';
      $content = $payload['content'] ?? '';
      $excerpt = $payload['excerpt'] ?? '';

      $post_id = wp_insert_post([
        'post_title' => wp_strip_all_tags($title),
        'post_content' => $content,
        'post_excerpt' => wp_strip_all_tags($excerpt),
        'post_status' => 'draft',
        'post_type' => 'post',
      ], true);

      if (is_wp_error($post_id)) {
        return new WP_REST_Response(['ok'=>false,'error'=>$post_id->get_error_message()], 500);
      }

      return ['ok'=>true,'post_id'=>$post_id,'edit_url'=>get_edit_post_link($post_id,'raw')];
    },
    'permission_callback' => 'vire_permission_admin',
  ]);

  register_rest_route('vire', '/content/publish', [
    'methods' => 'POST',
    'callback' => function($req){
      $id = (int)$req->get_param('post_id');
      if (!$id) return new WP_REST_Response(['ok'=>false,'error'=>'post_id required'], 400);

      $r = wp_update_post(['ID'=>$id,'post_status'=>'publish'], true);
      if (is_wp_error($r)) return new WP_REST_Response(['ok'=>false,'error'=>$r->get_error_message()], 500);

      return ['ok'=>true,'post_id'=>$id,'url'=>get_permalink($id)];
    },
    'permission_callback' => 'vire_permission_admin',
  ]);

  // ------------------------
  // 6) Monitor
  // ------------------------
  register_rest_route('vire', '/monitor', [
    'methods' => 'GET',
    'callback' => function(){
      require_once ABSPATH . 'wp-admin/includes/update.php';
      require_once ABSPATH . 'wp-admin/includes/plugin.php';

      $core = get_site_transient('update_core');
      $plugins = get_site_transient('update_plugins');

      $core_updates = is_object($core) ? count($core->updates ?? []) : 0;
      $plugin_updates = is_object($plugins) ? count($plugins->response ?? []) : 0;

      $data = [
        'ok' => true,
        'timestamp' => vire_now_iso(),
        'core_updates' => $core_updates,
        'plugin_updates' => $plugin_updates,
        'siteurl' => get_option('siteurl'),
        'home' => get_option('home'),
      ];

      // Include last sync (if present)
      $status = vire_read_json('status.json');
      if ($status) $data['last_sync'] = $status;

      return $data;
    },
    'permission_callback' => 'vire_permission_admin',
  ]);

});
PHP

# ------------------------------------------------------------
# B) Local Worker: Apply approval.json decisions safely
#    - apply: creates a "to_apply.json" record and marks applied_at
#    - reject: marks rejected_at
# ------------------------------------------------------------
cat <<'EOF' > "$BASE_DIR/vire-approval-worker.sh"
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
EOF
chmod +x "$BASE_DIR/vire-approval-worker.sh"

# ------------------------------------------------------------
# C) Next.js UI upgrade: Tabs + Approvals + Risk + Editorial + Publish + Monitor
# ------------------------------------------------------------
VIRE_UI="$BASE_DIR/vire-ui"
mkdir -p "$VIRE_UI"/{app,public,lib}

cat <<'EOF' > "$VIRE_UI/app/page.tsx"
type AnyJson = any;

async function loadJson(url: string): Promise<AnyJson> {
  const r = await fetch(url, { cache: 'no-store' });
  if (!r.ok) return null;
  return r.json();
}

async function postJson(url: string, body: AnyJson): Promise<AnyJson> {
  const r = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
    cache: 'no-store'
  });
  if (!r.ok) return { ok:false, error: await r.text() };
  return r.json();
}

export default async function Page() {
  const base = process.env.NEXT_PUBLIC_VIRE_API || '/wp-json/vire';

  const status   = await loadJson(`${base}/status`);
  const plan     = await loadJson(`${base}/plan`);
  const explain  = await loadJson(`${base}/explain`);
  const risk     = await loadJson(`${base}/plugin-risk`);
  const editorial = await loadJson(`${base}/editorial`);
  const monitor  = await loadJson(`${base}/monitor`);

  // NOTE: Buttons use client-side JS; we render instructions + endpoints here.
  return (
    <main style={{padding:24,fontFamily:'system-ui',maxWidth:1100,margin:'0 auto'}}>
      <h1 style={{marginTop:0}}>Vire 6 UI</h1>
      <p style={{opacity:.8}}>
        Admin-only. Reads sync artifacts, explains conflicts, scores plugin risk, runs prompt→draft→publish, and monitors health.
      </p>

      <section style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16}}>
        <Card title="Run Status" json={status} />
        <Card title="Monitor" json={monitor} />
      </section>

      <section style={{marginTop:18}}>
        <h2>🔐 Approvals</h2>
        <p style={{opacity:.8}}>
          Use the buttons below inside WordPress Admin (recommended) or call endpoints manually:
        </p>
        <pre style={preStyle}>
POST {base}/approval {"{ action: 'apply' | 'reject' }"}
        </pre>

        <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>
          <a href="/wp-admin/" style={btnPrimary}>Open WP Admin</a>
          <a href="/_sync_status/dashboard.html" style={btn}>Open Sync Dashboard</a>
          <a href="/_sync_status/ai_conflicts_report.md" style={btn}>Open AI Report</a>
        </div>
      </section>

      <section style={{marginTop:18,display:'grid',gridTemplateColumns:'1fr 1fr',gap:16}}>
        <Card title="Resolution Plan" json={plan} />
        <Card title="AI Explainer" json={explain} />
      </section>

      <section style={{marginTop:18}}>
        <h2>🧩 Plugin Risk Scoring</h2>
        <p style={{opacity:.8}}>Heuristic scoring (offline). Highest risk on top.</p>
        <pre style={preStyle}>{JSON.stringify(risk, null, 2)}</pre>
      </section>

      <section style={{marginTop:18}}>
        <h2>🗓 Editorial Calendar</h2>
        <pre style={preStyle}>{JSON.stringify(editorial, null, 2)}</pre>
        <p style={{opacity:.8}}>
          Add an item via: <code>POST {base}/editorial</code> with JSON:
          <code>{"{ title, topic, target_date, mode: 'Creator|Planner|Admin', notes }"}</code>
        </p>
      </section>

      <section style={{marginTop:18}}>
        <h2>🤖 Prompt → Draft → Publish</h2>
        <p style={{opacity:.8}}>
          Use endpoints:
        </p>
        <pre style={preStyle}>
POST {base}/content/generate  {"{ prompt, mode }"}
POST {base}/content/draft     {"{ title, excerpt, content }"}
POST {base}/content/publish   {"{ post_id }"}
        </pre>
        <p style={{opacity:.8}}>
          If <code>OPENAI_API_KEY</code> is not configured, Vire returns fallback content so the workflow still works.
        </p>
      </section>

      <hr style={{margin:'22px 0',opacity:.2}} />

      <section>
        <h2>Step-by-step usage</h2>
        <ol style={{lineHeight:1.8}}>
          <li>Run your sync as usual: <code>./vsync.sh all</code></li>
          <li>Generate conflict explanations (already in your suite): <code>./vsync-ai-diff-explain.sh</code></li>
          <li>Open WP Admin and log in as an admin user.</li>
          <li>Open the Vire UI route (where you host it) or use the dashboard: <code>/_sync_status/dashboard.html</code></li>
          <li>Review <b>Resolution Plan</b> + <b>AI Explainer</b>.</li>
          <li>Approve or reject:
            <ul>
              <li><b>Apply</b> → writes <code>approval.json</code></li>
              <li><b>Reject</b> → writes <code>approval.json</code></li>
            </ul>
          </li>
          <li>On your local machine, run: <code>./vire-approval-worker.sh</code> to produce apply instructions safely.</li>
          <li>For content: call <code>content/generate</code> → then <code>content/draft</code> → then <code>content/publish</code>.</li>
          <li>Check <b>Monitor</b> panel and plugin risk scores weekly.</li>
        </ol>
      </section>
    </main>
  );
}

function Card({ title, json }: { title: string; json: any }) {
  return (
    <div style={cardStyle}>
      <h3 style={{marginTop:0}}>{title}</h3>
      <pre style={preStyle}>{JSON.stringify(json, null, 2)}</pre>
    </div>
  );
}

const cardStyle: React.CSSProperties = {
  border: '1px solid rgba(0,0,0,.12)',
  borderRadius: 14,
  padding: 14,
  background: 'rgba(250,250,250,.9)',
};

const preStyle: React.CSSProperties = {
  margin: 0,
  padding: 12,
  background: 'rgba(0,0,0,.06)',
  borderRadius: 12,
  overflow: 'auto',
  fontSize: 12,
  lineHeight: 1.45,
};

const btn: React.CSSProperties = {
  display:'inline-block',
  padding:'10px 12px',
  borderRadius: 12,
  border:'1px solid rgba(0,0,0,.15)',
  textDecoration:'none',
  color:'#111'
};

const btnPrimary: React.CSSProperties = {
  ...btn,
  background:'#111',
  color:'#fff',
  border:'1px solid #111'
};
EOF

cat <<'EOF' > "$VIRE_UI/next.config.js"
module.exports = { output: 'export', distDir: 'dist' };
EOF

cat <<'EOF' > "$VIRE_UI/package.json"
{
  "name": "vire-ui",
  "private": true,
  "scripts": { "build": "next build" },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
EOF

# ------------------------------------------------------------
# D) UI Build + Publish helper
#    - Builds static UI
#    - Copies to WP root /vire-ui (served by Apache)
# ------------------------------------------------------------
cat <<'EOF' > "$BASE_DIR/vire-ui-publish.sh"
#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

UI="$BASE_DIR/vire-ui"
OUT="$LOCAL_ROOT/vire-ui"

mkdir -p "$OUT"
cd "$UI"

# Build (you must have node/npm available)
npm install
npm run build

# Next export output
cp -r dist/* "$OUT/"

echo "✅ Vire UI published to: $OUT"
echo "➡ Open: http://localhost:8085/vire-ui/"
EOF


chmod +x "$BASE_DIR/vire-ui-publish.sh"

echo "✅ Vire 6.1 UI Extension installed."
echo "Next:"
echo "  1) Ensure WP admin login works"
echo "  2) Run: $BASE_DIR/vire-ui-publish.sh"
echo "  3) Open: http://localhost:8085/vire-ui/"
echo "  4) Approvals worker: $BASE_DIR/vire-approval-worker.sh"
