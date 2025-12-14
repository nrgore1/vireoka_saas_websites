#!/usr/bin/env python3
import json, pathlib
from providers import pick_provider

"""
Reads: vire-agent/v3/outputs/site.json
Writes: vire-agent/export/pages/*.html (Gutenberg-ready blocks)
Also writes: vire-agent/export/meta.json (SEO meta per page)
"""

site_path = pathlib.Path("vire-agent/v3/outputs/site.json")
if not site_path.exists():
    raise SystemExit("❌ Missing vire-agent/v3/outputs/site.json (run V3 or SaaS launcher first)")

site = json.loads(site_path.read_text(encoding="utf-8"))
provider = pick_provider()

pages_dir = pathlib.Path("vire-agent/export/pages")
pages_dir.mkdir(parents=True, exist_ok=True)

meta = {}

def gut_wrap(inner_html: str) -> str:
    return f"""<!-- wp:group -->
<div class="wp-block-group">
{inner_html}
</div>
<!-- /wp:group -->
"""

for page in site["pages"]:
    prompt = (
        f"Generate a concise, premium, investor-grade landing page section copy for '{page}'.\n"
        f"Product: {site.get('product_name')}\n"
        f"Audience: {site.get('audience')}\n"
        f"Keywords: {', '.join(site.get('keywords', []))}\n"
        "Requirements: E-E-A-T, clear CTA, enterprise tone, no technical IP leakage.\n"
    )

    text = provider.generate(prompt)
    html = f"<h1>{page}</h1>\n<p>{text.replace('\\n','</p>\\n<p>')}</p>\n"
    slug = page.lower().replace(" ", "-")
    (pages_dir / f"{slug}.html").write_text(gut_wrap(html), encoding="utf-8")

    meta[slug] = {
        "title": f"{site.get('product_name')} | {page}",
        "description": f"{site.get('product_name')} — {page}. Enterprise-ready AI platform by Vireoka.",
        "og_title": f"{site.get('product_name')} — {page}",
        "og_description": f"Explore {page} for {site.get('product_name')}.",
    }

(pathlib.Path("vire-agent/export/meta.json")).write_text(json.dumps(meta, indent=2), encoding="utf-8")
print("✅ Rich copy generated. Pages:", len(site["pages"]))
