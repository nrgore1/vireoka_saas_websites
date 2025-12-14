#!/usr/bin/env python3
import os, json, re, sys
from pathlib import Path
from datetime import datetime, timezone

"""
Agentic V5:
- Takes a prompt + product + tone
- Calls an LLM to produce:
  (a) site.json spec (pages, slugs, seo)
  (b) page blocks content (headlines, sections, copy)
- Renders Gutenberg-friendly HTML (block comments + clean div structure)
- Deterministic fallback if no API key or request fails.
"""

def utc_now():
    return datetime.now(timezone.utc).isoformat()

def slugify(s: str) -> str:
    s = (s or "").strip().lower()
    s = re.sub(r"[^a-z0-9\\s-]", "", s)
    s = re.sub(r"\\s+", "-", s).strip("-")
    return s or "site"

def load_vault_env():
    # Prefer V2 vault file if present
    candidates = [
        Path("vire-agent/v2/vault/.vault.env"),
        Path("vire-agent/v5/.vault.env"),
        Path(".env")
    ]
    for p in candidates:
        if p.exists():
            for line in p.read_text(encoding="utf-8").splitlines():
                line=line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k,v = line.split("=",1)
                os.environ.setdefault(k.strip(), v.strip())
            return str(p)
    return None

def llm_call(prompt: str):
    """
    OpenAI-compatible call using env:
      OPENAI_API_KEY
      OPENAI_BASE_URL (optional)
      OPENAI_MODEL (optional, default gpt-4.1-mini or gpt-5 if available)
    """
    api_key = os.getenv("OPENAI_API_KEY","").strip()
    if not api_key:
        return None, "missing OPENAI_API_KEY"

    base_url = os.getenv("OPENAI_BASE_URL","https://api.openai.com/v1").rstrip("/")
    model = os.getenv("OPENAI_MODEL","gpt-4.1-mini")

    import requests
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type":"application/json"}
    payload = {
        "model": model,
        "temperature": 0.7,
        "messages": [
            {"role":"system","content":(
                "You are Vire, an elite website generator. "
                "Return STRICT JSON only. No markdown. No commentary."
            )},
            {"role":"user","content": prompt}
        ]
    }
    r = requests.post(f"{base_url}/chat/completions", headers=headers, json=payload, timeout=60)
    if r.status_code != 200:
        return None, f"llm_error: {r.status_code} {r.text[:200]}"
    data = r.json()
    txt = data["choices"][0]["message"]["content"]
    try:
        return json.loads(txt), "ok"
    except Exception as e:
        return None, f"json_parse_error: {e} | content_head={txt[:120]}"

def build_prompt(user_prompt: str, product: str, tone: str, layout_lib: dict):
    # Force JSON schema for reliability
    return f"""
Generate a complete website plan for:
- Company: Vireoka LLC
- Product: {product}
- Tone: {tone}

User prompt:
{user_prompt}

You MUST return valid JSON with this schema:
{{
  "site_id": "string",
  "product_name": "string",
  "tone": "string",
  "base_url": "http://localhost:8085",
  "pages": [
    {{
      "title": "Home",
      "slug": "home",
      "meta_title": "string",
      "meta_description": "string",
      "h1": "string",
      "sections": [
        {{
          "type": "hero|bento|split|grid|steps|stats|cards|pricing|accordion|cta_form|cta_banner|eeat|footer",
          "headline": "string",
          "subhead": "string",
          "bullets": ["string"],
          "cards": [{{"title":"string","text":"string","badge":"string"}}],
          "ctas": [{{"label":"string","href":"string"}}],
          "disclaimer": "string"
        }}
      ]
    }}
  ],
  "schema": {{
    "organization": {{}},
    "software_app": {{}}
  }}
}}

Use these layout patterns to choose sections (you may omit fields not needed):
{json.dumps(layout_lib.get("layouts",{}), indent=2)}

Hard rules:
- Include at least one "Founder's Note" (E-E-A-T) section on Home and each product page.
- Include SEO keywords naturally in H1/H2/meta: "AI agent frameworks", "Greenfield AI opportunities", "Quantum secure stablecoin", "Niche dating platform creator".
- If the product is stablecoin/finance, add a short YMYL disclaimer section in footer.
- Keep copy crisp and investor-grade. No fluff.
Return JSON only.
""".strip()

def section_to_gutenberg(sec: dict) -> str:
    # Minimal Gutenberg-ish wrapper for portability
    t = sec.get("type","cards")
    headline = sec.get("headline","")
    subhead = sec.get("subhead","")
    bullets = sec.get("bullets") or []
    cards = sec.get("cards") or []
    ctas = sec.get("ctas") or []
    disclaimer = sec.get("disclaimer","")

    out = []
    out.append('<!-- wp:group {"className":"vire-card"} -->')
    out.append('<div class="wp-block-group vire-card">')

    if headline:
        out.append(f'<!-- wp:heading {"level":2} --><h2>{headline}</h2><!-- /wp:heading -->')
    if subhead:
        out.append(f'<!-- wp:paragraph --><p>{subhead}</p><!-- /wp:paragraph -->')

    if t == "hero":
        # hint for neural canvas (V2/V5 assets)
        out.append('<!-- wp:html --><div class="vire-neural-host"><canvas class="vire-neural-canvas"></canvas></div><!-- /wp:html -->')

    if bullets:
        out.append('<!-- wp:list --><ul>')
        for b in bullets[:12]:
            out.append(f"<li>{b}</li>")
        out.append("</ul><!-- /wp:list -->")

    if cards:
        out.append('<!-- wp:columns --><div class="wp-block-columns">')
        for c in cards[:6]:
            title = c.get("title","")
            text = c.get("text","")
            badge = c.get("badge","")
            out.append('<!-- wp:column --><div class="wp-block-column">')
            out.append('<div class="vire-card">')
            if badge:
                out.append(f'<span class="vire-badge">{badge}</span>')
            if title:
                out.append(f"<h3>{title}</h3>")
            if text:
                out.append(f"<p>{text}</p>")
            out.append("</div>")
            out.append("</div><!-- /wp:column -->")
        out.append("</div><!-- /wp:columns -->")

    if ctas:
        out.append('<!-- wp:buttons --><div class="wp-block-buttons">')
        for c in ctas[:2]:
            lab = c.get("label","Learn more")
            href = c.get("href","#")
            out.append('<!-- wp:button {"className":"vire-cta"} --><div class="wp-block-button vire-cta">')
            out.append(f'<a class="wp-block-button__link wp-element-button" href="{href}">{lab}</a>')
            out.append("</div><!-- /wp:button -->")
        out.append("</div><!-- /wp:buttons -->")

    if disclaimer:
        out.append(f'<!-- wp:paragraph --><p style="opacity:.8;font-size:13px">{disclaimer}</p><!-- /wp:paragraph -->')

    out.append("</div>")
    out.append("<!-- /wp:group -->")
    return "\n".join(out)

def render_page(page: dict) -> str:
    # Gutenberg export (no <html> needed; WP stores blocks in post_content)
    h1 = page.get("h1") or page.get("title","")
    meta_title = page.get("meta_title","")
    meta_desc = page.get("meta_description","")
    sections = page.get("sections") or []

    parts = []
    parts.append(f'<!-- VIRE_META: {json.dumps({"meta_title":meta_title,"meta_description":meta_desc})} -->')
    parts.append(f'<!-- wp:heading {"level":1} --><h1>{h1}</h1><!-- /wp:heading -->')

    for sec in sections:
        parts.append(section_to_gutenberg(sec))

    return "\n\n".join(parts) + "\n"

def fallback_site(product: str, tone: str):
    pid = slugify(product)
    return {
        "site_id": f"{pid}-local",
        "product_name": product,
        "tone": tone,
        "base_url": "http://localhost:8085",
        "pages": [
            {
                "title":"Home",
                "slug":"home",
                "meta_title": f"Vireoka | {product}",
                "meta_description":"Agentic AI websites. AI agent frameworks, Greenfield AI opportunities.",
                "h1": f"{product} — Built with Agentic AI",
                "sections":[
                    {"type":"hero","headline":"De-risking innovation through Agentic AI","subhead":"AI agent frameworks for real outcomes. Greenfield AI opportunities at scale.","bullets":["Fast launch","SEO-ready","Modular theme system"],"ctas":[{"label":"Join Waitlist","href":"#waitlist"}]},
                    {"type":"eeat","headline":"Founder’s Note","subhead":"I’m building Vireoka as a compounding portfolio of AI products with rigorous engineering and responsible deployment.","bullets":["Execution-first","Security-minded","Investor-grade reporting"]},
                    {"type":"cta_form","headline":"Investor / Early Access","subhead":"Get on the waitlist for private demos and early partner access.","bullets":["Email capture","Priority access","Updates"],"ctas":[{"label":"Subscribe","href":"#waitlist"}]}
                ]
            },
            {
                "title":"Products",
                "slug":"products",
                "meta_title":"Vireoka Products",
                "meta_description":"AI agent frameworks across AtmaSphere, dating platform creator, and quantum secure stablecoin.",
                "h1":"Vireoka Ecosystem",
                "sections":[
                    {"type":"grid","headline":"Portfolio","subhead":"AI agent frameworks across verticals.","cards":[
                        {"title":"AtmaSphere LLM","text":"Aligned reasoning + RAG.","badge":"Priority/Beta"},
                        {"title":"Dating Platform Builder","text":"Niche dating platform creator.","badge":"Priority/Beta"},
                        {"title":"Quantum-Secure Stablecoin","text":"Quantum secure finance stack.","badge":"Priority/Beta"}
                    ]}
                ]
            }
        ],
        "schema":{
            "organization":{"@context":"https://schema.org","@type":"Organization","name":"Vireoka LLC","url":"https://vireoka.com"},
            "software_app":{"@context":"https://schema.org","@type":"SoftwareApplication","name":product,"applicationCategory":"BusinessApplication"}
        }
    }

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt", required=True)
    ap.add_argument("--product", required=True)
    ap.add_argument("--tone", default="elite-neural-luxe")
    ap.add_argument("--out", default="vire-agent/v5/outputs")
    args = ap.parse_args()

    out_dir = Path(args.out)
    pages_dir = out_dir / "pages"
    out_dir.mkdir(parents=True, exist_ok=True)
    pages_dir.mkdir(parents=True, exist_ok=True)

    vault_used = load_vault_env()

    layout_lib = json.loads((Path(__file__).parent / "layout_library.json").read_text(encoding="utf-8"))
    full_prompt = build_prompt(args.prompt, args.product, args.tone, layout_lib)

    data, status = llm_call(full_prompt)
    if not data:
        data = fallback_site(args.product, args.tone)
        status = f"fallback:{status}"

    # Normalize
    data["product_name"] = data.get("product_name") or args.product
    data["tone"] = data.get("tone") or args.tone
    data["generated_at"] = utc_now()
    data["generator"] = "vire-agentic-v5"
    data["llm_status"] = status
    if vault_used:
        data["vault_loaded_from"] = vault_used

    # Write site.json
    (out_dir / "site.json").write_text(json.dumps(data, indent=2), encoding="utf-8")

    # Write pages
    pages = data.get("pages") or []
    for p in pages:
        slug = slugify(p.get("slug") or p.get("title") or "page")
        html = render_page(p)
        (pages_dir / f"{slug}.html").write_text(html, encoding="utf-8")

    print("✅ Agentic site written:")
    print(" -", out_dir / "site.json")
    print(" -", pages_dir)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
