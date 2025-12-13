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
