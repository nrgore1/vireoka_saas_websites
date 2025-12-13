#!/usr/bin/env python3
import json, os, subprocess, sys, textwrap
from datetime import datetime, timezone

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def sh(cmd: list[str]) -> str:
  return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT).strip()

def load_json(path: str) -> dict:
  if not os.path.exists(path):
    return {}
  with open(path, "r", encoding="utf-8") as f:
    return json.load(f)

def summarize_changes(repo_root: str) -> str:
  # Best-effort: if this is in a git repo, use git diff summary.
  try:
    out = sh(["git", "-C", repo_root, "status", "--porcelain"])
    lines = [ln for ln in out.splitlines() if ln.strip()]
    if not lines:
      return "No local git changes detected."
    # limit
    return "\n".join(lines[:120]) + ("" if len(lines) <= 120 else "\n…(truncated)")
  except Exception:
    return "Git summary unavailable."

def heuristic_recommendation(conflict: bool, sync_mode: str) -> dict:
  # Simple, practical playbook
  if not conflict:
    return {
      "decision": "no_action",
      "reason": "No conflict detected between local and remote snapshots.",
      "recommended_next": ["Proceed with normal sync.", "Render dashboard HTML for confirmation."]
    }

  # Conflict detected
  return {
    "decision": "review_required",
    "reason": "Conflict detected: local and remote content hashes differ.",
    "recommended_next": [
      "Run a DRY-RUN and inspect rsync output for affected files.",
      "If you intentionally changed LOCAL and want it to win: set SYNC_MODE=push-only for one run.",
      "If remote is source of truth: set SYNC_MODE=pull-only for one run.",
      "If unsure: take a backup, then pull remote into a separate temp folder and diff."
    ],
    "one_run_commands": [
      "./vsync.sh dry",
      "SYNC_MODE=push-only ./vsync.sh all",
      "SYNC_MODE=pull-only ./vsync.sh all"
    ]
  }

def maybe_openai_advice(context: str) -> str | None:
  api_key = os.getenv("OPENAI_API_KEY", "").strip()
  if not api_key:
    return None
  # Optional: keep it dependency-free by using curl.
  # If the call fails, we just skip it.
  try:
    import urllib.request
    import urllib.error

    payload = {
      "model": os.getenv("OPENAI_MODEL", "gpt-5"),
      "input": context
    }

    req = urllib.request.Request(
      "https://api.openai.com/v1/responses",
      data=json.dumps(payload).encode("utf-8"),
      headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
      },
      method="POST"
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
      data = json.loads(resp.read().decode("utf-8", errors="ignore"))
    # best-effort: Responses API returns output array; extract text
    out = []
    for item in data.get("output", []):
      for c in item.get("content", []):
        if c.get("type") == "output_text":
          out.append(c.get("text", ""))
    text = "\n".join(out).strip()
    return text or None
  except Exception:
    return None

def main():
  # vconfig is bash; we rely on vconfig-derived json paths existing
  status_dir = None
  # try to read from environment first
  # (vsync.sh can export these before invoking)
  local_conflicts = os.getenv("LOCAL_CONFLICTS", "")
  local_status_dir = os.getenv("LOCAL_STATUS_DIR", "")

  # fallback: common default relative to LOCAL_ROOT in vconfig
  # if not passed, attempt to locate _sync_status in repo
  candidates = [
    os.path.join(os.getcwd(), "_sync_status", "conflicts.json"),
    os.path.join(os.getcwd(), "wp", "_sync_status", "conflicts.json"),
    os.path.join(os.getcwd(), "wp-content", "_sync_status", "conflicts.json"),
  ]

  conflicts_path = local_conflicts if local_conflicts else next((p for p in candidates if os.path.exists(p)), "")
  if not conflicts_path:
    print("❌ Could not find conflicts.json. Run ./vsync-conflicts.sh first.", file=sys.stderr)
    sys.exit(1)

  conflicts = load_json(conflicts_path)
  conflict = bool(conflicts.get("conflict", False))
  sync_mode = os.getenv("SYNC_MODE", "two-way")

  repo_root = os.getcwd()
  git_summary = summarize_changes(repo_root)

  rec = heuristic_recommendation(conflict, sync_mode)

  report = {
    "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "conflicts_file": conflicts_path,
    "conflict": conflict,
    "sync_mode": sync_mode,
    "git_summary": git_summary,
    "heuristic": rec,
    "ai_advice": None,
  }

  # Optional AI advice
  context = textwrap.dedent(f"""
  You are assisting with resolving a two-way rsync conflict for a WordPress repo.
  Provide a short recommendation and the safest next command to run.
  Context:
  - sync_mode: {sync_mode}
  - conflict: {conflict}
  - git_status:
  {git_summary}
  - conflicts.json:
  {json.dumps(conflicts, indent=2)}
  """).strip()

  ai = maybe_openai_advice(context)
  if ai:
    report["ai_advice"] = ai

  out_path = os.path.join(os.path.dirname(conflicts_path), "resolution.json")
  with open(out_path, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)

  print(f"🧠 Resolution report written: {out_path}")
  print("")
  print("Heuristic decision:", rec.get("decision"))
  for line in rec.get("recommended_next", []):
    print(" -", line)
  if ai:
    print("\nAI advice (optional):\n")
    print(ai)

if __name__ == "__main__":
  main()
