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
