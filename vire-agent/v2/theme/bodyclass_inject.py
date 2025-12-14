#!/usr/bin/env python3
import json, re, pathlib, sys

def slugify(s):
    s = s.lower().strip()
    s = re.sub(r'[^a-z0-9\s-]', '', s)
    return re.sub(r'\s+', '-', s)

site_path = pathlib.Path("site.json")
if not site_path.exists():
    print("❌ site.json not found")
    sys.exit(1)

site = json.loads(site_path.read_text())
site_id = slugify(site.get("site_id", "site"))
product = slugify(site.get("product_name", "product"))
tone = slugify(site.get("tone", "neural-luxe"))

pages_dir = pathlib.Path("vire-agent/export/pages")
if not pages_dir.exists():
    print("❌ export/pages missing")
    sys.exit(1)

for page in pages_dir.glob("*.html"):
    html = page.read_text()
    if "vire-site--" in html:
        continue

    wrapper_open = f"""<!-- wp:group -->
<div class="wp-block-group vire-site vire-site--{site_id} vire-product--{product} vire-tone--{tone}"
     data-vire-site="{site_id}"
     data-vire-product="{product}"
     data-vire-tone="{tone}">
"""
    wrapper_close = "</div><!-- /wp:group -->"

    page.write_text(wrapper_open + html + wrapper_close)

print("✅ Body classes injected")
