#!/usr/bin/env python3
import argparse
import datetime
import json
import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

MAX_TEXT_BYTES = 256_000  # only diff small-ish text files
SNIPPET_LINES = 80

@dataclass
class ConflictItem:
    path: str
    local_ts: Optional[str] = None
    remote_ts: Optional[str] = None
    scope: str = "unknown"  # plugins/themes/uploads/other
    local_abs: Optional[str] = None
    remote_abs: Optional[str] = None

def now_utc() -> str:
    return datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")

def sh(cmd: List[str], check: bool = False, text: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=text)

def load_env_from_vconfig(repo_tools_dir: Path) -> Dict[str, str]:
    """
    We rely on vconfig.sh being sourced by the caller bash script for runtime variables.
    But for Python we still need key paths. We read them from environment, with sane fallbacks.
    """
    env = dict(os.environ)
    # Expected env vars from vconfig.sh:
    # LOCAL_PLUGINS, LOCAL_THEMES, LOCAL_UPLOADS
    # REMOTE_PLUGINS, REMOTE_THEMES, REMOTE_UPLOADS, REMOTE_ROOT
    # REMOTE_USER, REMOTE_HOST, REMOTE_PORT
    required = ["REMOTE_USER", "REMOTE_HOST", "REMOTE_PORT"]
    for r in required:
        if not env.get(r):
            # allow missing if user only wants local report without remote diff fetch
            pass
    return env

def parse_conflicts_json(p: Path) -> List[ConflictItem]:
    data = json.loads(p.read_text(encoding="utf-8"))
    items = []

    # Accept flexible formats:
    # { "conflicts": [ { "path": "...", "local_ts": "...", "remote_ts":"..." , "scope":"plugins"} ] }
    # OR { "conflicts": [ "path|local_ts|remote_ts", ... ] }
    raw = data.get("conflicts", [])
    for it in raw:
        if isinstance(it, str):
            parts = it.split("|")
            path = parts[0].strip() if parts else ""
            local_ts = parts[1].strip() if len(parts) > 1 else None
            remote_ts = parts[2].strip() if len(parts) > 2 else None
            items.append(ConflictItem(path=path, local_ts=local_ts, remote_ts=remote_ts))
        elif isinstance(it, dict):
            items.append(ConflictItem(
                path=str(it.get("path") or it.get("file") or ""),
                local_ts=(str(it.get("local_ts")) if it.get("local_ts") is not None else None),
                remote_ts=(str(it.get("remote_ts")) if it.get("remote_ts") is not None else None),
                scope=str(it.get("scope") or "unknown"),
                local_abs=(str(it.get("local_abs")) if it.get("local_abs") else None),
                remote_abs=(str(it.get("remote_abs")) if it.get("remote_abs") else None),
            ))
    return [x for x in items if x.path]

def parse_conflicts_txt(p: Path) -> List[ConflictItem]:
    items = []
    for line in p.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        path = parts[0].strip()
        local_ts = parts[1].strip() if len(parts) > 1 else None
        remote_ts = parts[2].strip() if len(parts) > 2 else None
        items.append(ConflictItem(path=path, local_ts=local_ts, remote_ts=remote_ts))
    return items

def guess_scope(env: Dict[str, str], rel_path: str) -> str:
    p = rel_path.lower()
    if "wp-content/plugins" in p:
        return "plugins"
    if "wp-content/themes" in p:
        return "themes"
    if "wp-content/uploads" in p:
        return "uploads"
    # If it looks like a plugin/theme relative file (no wp-content prefix), infer by existence later.
    return "unknown"

def find_local_file(env: Dict[str, str], rel_path: str) -> Tuple[Optional[str], str]:
    """
    Try to resolve a conflict path to an actual local file.
    Paths might be:
      - relative inside plugins/themes/uploads (e.g. seo-by-rank-math/rank-math.php)
      - full wp-content/... path
    """
    candidates = []

    lp = env.get("LOCAL_PLUGINS")
    lt = env.get("LOCAL_THEMES")
    lu = env.get("LOCAL_UPLOADS")

    # normalized
    rel = rel_path.lstrip("./")
    rel = rel.replace("\\", "/")

    if "wp-content/plugins/" in rel:
        if lp:
            candidates.append(Path(lp) / rel.split("wp-content/plugins/", 1)[1])
    if "wp-content/themes/" in rel:
        if lt:
            candidates.append(Path(lt) / rel.split("wp-content/themes/", 1)[1])
    if "wp-content/uploads/" in rel:
        if lu:
            candidates.append(Path(lu) / rel.split("wp-content/uploads/", 1)[1])

    # If no prefix, try each root
    if lp:
        candidates.append(Path(lp) / rel)
    if lt:
        candidates.append(Path(lt) / rel)
    if lu:
        candidates.append(Path(lu) / rel)

    for c in candidates:
        if c.exists() and c.is_file():
            # scope by root
            if lp and str(c).startswith(str(Path(lp))):
                return str(c), "plugins"
            if lt and str(c).startswith(str(Path(lt))):
                return str(c), "themes"
            if lu and str(c).startswith(str(Path(lu))):
                return str(c), "uploads"
            return str(c), "unknown"
    return None, "unknown"

def remote_cat(env: Dict[str, str], remote_abs: str) -> Optional[bytes]:
    user = env.get("REMOTE_USER")
    host = env.get("REMOTE_HOST")
    port = env.get("REMOTE_PORT")
    if not (user and host and port):
        return None

    # Use base64 to avoid encoding issues
    cmd = [
        "ssh", "-p", str(port), f"{user}@{host}",
        f"test -f '{remote_abs}' && python3 - <<'PY'\n"
        f"import base64\n"
        f"p=r'''{remote_abs}'''\n"
        f"with open(p,'rb') as f:\n"
        f"  b=f.read({MAX_TEXT_BYTES}+1)\n"
        f"print(base64.b64encode(b).decode('ascii'))\n"
        f"PY"
    ]
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if r.returncode != 0 or not r.stdout.strip():
        return None
    import base64
    try:
        b = base64.b64decode(r.stdout.strip().encode("ascii"))
        return b
    except Exception:
        return None

def resolve_remote_abs(env: Dict[str, str], item: ConflictItem, scope_hint: str) -> Optional[str]:
    """
    Convert relative paths into absolute remote paths using REMOTE_PLUGINS/THEMES/UPLOADS.
    """
    rel = item.path.lstrip("./").replace("\\", "/")
    rp = env.get("REMOTE_PLUGINS")
    rt = env.get("REMOTE_THEMES")
    ru = env.get("REMOTE_UPLOADS")

    if item.remote_abs:
        return item.remote_abs

    if "wp-content/plugins/" in rel and rp:
        return str(Path(rp) / rel.split("wp-content/plugins/", 1)[1])
    if "wp-content/themes/" in rel and rt:
        return str(Path(rt) / rel.split("wp-content/themes/", 1)[1])
    if "wp-content/uploads/" in rel and ru:
        return str(Path(ru) / rel.split("wp-content/uploads/", 1)[1])

    # If no prefix, decide by hint
    if scope_hint == "plugins" and rp:
        return str(Path(rp) / rel)
    if scope_hint == "themes" and rt:
        return str(Path(rt) / rel)
    if scope_hint == "uploads" and ru:
        return str(Path(ru) / rel)

    # Try each (best effort)
    if rp:
        return str(Path(rp) / rel)
    return None

def is_probably_text(b: bytes) -> bool:
    if not b:
        return False
    if b.startswith(b"\x7fELF") or b[:4] in (b"\x89PNG", b"GIF8", b"%PDF"):
        return False
    # NUL byte heuristic
    if b"\x00" in b[:4096]:
        return False
    return True

def summarize_diff(local_text: str, remote_text: str) -> Dict[str, object]:
    import difflib
    lt = local_text.splitlines()
    rt = remote_text.splitlines()
    sm = difflib.SequenceMatcher(a=rt, b=lt)  # compare remote -> local
    added = removed = changed = 0
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "insert":
            added += (j2 - j1)
        elif tag == "delete":
            removed += (i2 - i1)
        elif tag == "replace":
            changed += max(i2 - i1, j2 - j1)

    # compact unified diff header (first N lines)
    ud = list(difflib.unified_diff(rt, lt, fromfile="remote", tofile="local", lineterm=""))
    preview = "\n".join(ud[:SNIPPET_LINES])

    return {
        "added_lines_est": added,
        "removed_lines_est": removed,
        "changed_lines_est": changed,
        "diff_preview": preview
    }

def plain_english_explainer(item: ConflictItem, scope: str, diff: Optional[Dict[str, object]]) -> str:
    p = item.path
    base = f"**{p}**"
    sc = scope

    reason = []
    if sc == "plugins":
        reason.append("This is a plugin file. Conflicts usually happen when a plugin updates on production (auto-updates) while local has a different version or manual edits.")
    elif sc == "themes":
        reason.append("This is a theme file. Conflicts usually mean the theme was edited locally (dev work) and also changed on production (hotfix or update).")
    elif sc == "uploads":
        reason.append("This is an uploads/media file. Conflicts can happen if a file was replaced or regenerated on production (e.g., image optimization) while local has a different copy.")
    else:
        reason.append("This file doesn’t clearly map to plugins/themes/uploads. It likely changed on both sides or was moved.")

    action = []
    if sc in ("plugins", "themes"):
        action.append("If this file belongs to your controlled codebase, prefer **local** and redeploy.")
        action.append("If production updated via WordPress updater, prefer **remote** and then pull to local to keep versions aligned.")
    elif sc == "uploads":
        action.append("Uploads are usually authoritative on production. Prefer **remote** unless you intentionally edited/replaced it locally.")
    else:
        action.append("Mark for manual review: decide which environment is authoritative for this file’s category.")

    if diff:
        a = diff.get("added_lines_est", 0)
        r = diff.get("removed_lines_est", 0)
        c = diff.get("changed_lines_est", 0)
        reason.append(f"Diff snapshot: ~{a} lines added, ~{r} removed, ~{c} modified (estimate).")
        # quick pattern hints
        preview = str(diff.get("diff_preview") or "")
        if "define(" in preview or "DB_" in preview:
            action.append("This looks like configuration changes. Ensure credentials and hosts match (avoid editing directly on prod).")
        if "/vendor/" in preview or "autoload.php" in preview:
            action.append("This resembles a Composer/vendor mismatch. On WordPress, vendor folders must exist—missing vendor often indicates an incomplete plugin copy.")

    out = []
    out.append(f"- {base}")
    if item.local_ts or item.remote_ts:
        out.append(f"  - timestamps: local={item.local_ts or '—'} • remote={item.remote_ts or '—'}")
    out.append(f"  - why this matters: {reason[0]}")
    for extra in reason[1:]:
        out.append(f"  - detail: {extra}")
    out.append("  - suggested next step:")
    for a2 in action:
        out.append(f"    - {a2}")
    return "\n".join(out)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--conflicts-json", required=True)
    ap.add_argument("--conflicts-txt", required=True)
    ap.add_argument("--out-md", required=True)
    ap.add_argument("--out-json", required=True)
    args = ap.parse_args()

    env = load_env_from_vconfig(Path.cwd())

    cj = Path(args.conflicts_json)
    ct = Path(args.conflicts_txt)

    items: List[ConflictItem] = []
    source = None

    if cj.exists():
        try:
            items = parse_conflicts_json(cj)
            source = str(cj)
        except Exception:
            items = []
    if not items and ct.exists():
        items = parse_conflicts_txt(ct)
        source = str(ct)

    report = {
        "generated_at": now_utc(),
        "source": source or "(none)",
        "conflicts_found": len(items),
        "items": []
    }

    md_lines = []
    md_lines.append(f"# Vire AI Conflict Explainer")
    md_lines.append(f"- generated_at: `{report['generated_at']}`")
    md_lines.append(f"- source: `{report['source']}`")
    md_lines.append(f"- conflicts_found: **{report['conflicts_found']}**")
    md_lines.append("")
    md_lines.append("## Plain-English Explanations")
    md_lines.append("")

    for it in items:
        local_abs, scope_local = find_local_file(env, it.path)
        scope = it.scope if it.scope != "unknown" else (scope_local if scope_local != "unknown" else guess_scope(env, it.path))
        it.local_abs = it.local_abs or local_abs
        it.scope = scope

        remote_abs = resolve_remote_abs(env, it, scope)
        it.remote_abs = it.remote_abs or remote_abs

        diff_summary = None

        # Try diff if both sides are accessible and text
        try:
            local_bytes = None
            if it.local_abs and Path(it.local_abs).exists():
                lb = Path(it.local_abs).read_bytes()[:MAX_TEXT_BYTES+1]
                local_bytes = lb

            remote_bytes = None
            if it.remote_abs:
                remote_bytes = remote_cat(env, it.remote_abs)

            if local_bytes and remote_bytes and len(local_bytes) <= MAX_TEXT_BYTES and len(remote_bytes) <= MAX_TEXT_BYTES:
                if is_probably_text(local_bytes) and is_probably_text(remote_bytes):
                    local_text = local_bytes.decode("utf-8", errors="replace")
                    remote_text = remote_bytes.decode("utf-8", errors="replace")
                    diff_summary = summarize_diff(local_text, remote_text)
        except Exception:
            diff_summary = None

        expl = plain_english_explainer(it, scope, diff_summary)

        md_lines.append(expl)
        if diff_summary and diff_summary.get("diff_preview"):
            md_lines.append("")
            md_lines.append("  <details><summary>diff preview (remote → local)</summary>\n\n```diff")
            md_lines.append(diff_summary["diff_preview"])
            md_lines.append("```\n</details>")
        md_lines.append("")

        report["items"].append({
            "path": it.path,
            "scope": scope,
            "local_ts": it.local_ts,
            "remote_ts": it.remote_ts,
            "local_abs": it.local_abs,
            "remote_abs": it.remote_abs,
            "diff": diff_summary
        })

    Path(args.out_md).write_text("\n".join(md_lines).strip() + "\n", encoding="utf-8")
    Path(args.out_json).write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(f"OK: wrote {args.out_md} and {args.out_json}")

if __name__ == "__main__":
    main()
