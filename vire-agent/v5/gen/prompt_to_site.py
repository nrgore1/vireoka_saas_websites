#!/usr/bin/env python3
import json, os, re, sys, datetime
from pathlib import Path

def utc_now_iso():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()

def slugify(s: str) -> str:
    s = (s or "").strip().lower()
    s = re.sub(r"[^a-z0-9\s-]", "", s)
    s = re.sub(r"\s+", "-", s).strip("-")
    return s or "site"

def heuristic_site(prompt: str, product: str, tone: str):
    # Deterministic fallback if no LLM key is present
    product_name = product.strip() if product.strip() else "Vireoka Product"
    pages = ["Home", "Products", "Pricing", "Enterprise", "About", "Contact"]
    return {
        "generated_at": utc_now_iso(),
        "site_id": slugify(product_name),
        "product_name": product_name,
        "tone": tone or "elite-neural-luxe",
        "prompt": prompt,
        "pages": pages,
        "sections": {
            "Home": ["Hero", "Ecosystem Grid", "Why Agents", "Waitlist CTA", "Footer"],
            "Products": ["Bento Grid", "Feature Cards", "Security/Trust", "CTA"],
            "Pricing": ["Plans", "Comparison", "FAQ", "Enterprise CTA"],
            "Enterprise": ["Request Demo", "Security", "SLA", "Contact"],
            "About": ["Founder Note", "Mission", "Roadmap", "CTA"],
            "Contact": ["Form", "Emails", "Partnerships"]
        }
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: prompt_to_site.py \"<prompt>\" [product_name] [tone] [out_path]")
        sys.exit(1)

    prompt = sys.argv[1]
    product = sys.argv[2] if len(sys.argv) > 2 else "Vireoka Product"
    tone = sys.argv[3] if len(sys.argv) > 3 else "elite-neural-luxe"
    out_path = Path(sys.argv[4]) if len(sys.argv) > 4 else Path("vire-agent/v5/outputs/site.json")
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # If you later wire an LLM, keep the same schema. For now we use deterministic output.
    site = heuristic_site(prompt, product, tone)
    out_path.write_text(json.dumps(site, indent=2), encoding="utf-8")
    print(f"✅ site.json written: {out_path}")

if __name__ == "__main__":
    main()
