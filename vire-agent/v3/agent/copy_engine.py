#!/usr/bin/env python3
import json, pathlib

site = json.load(open("vire-agent/v3/outputs/site.json"))

def page_copy(title):
    return f"""
<h1>{title}</h1>
<p><strong>{site['product_name']}</strong> is built for {site['audience']}.</p>
<p>Core focus: {', '.join(site['keywords'])}.</p>
"""

pages_dir = pathlib.Path("vire-agent/export/pages")
pages_dir.mkdir(parents=True, exist_ok=True)

for page in site["pages"]:
    slug = page.lower().replace(" ", "-")
    (pages_dir / f"{slug}.html").write_text(page_copy(page))

print("✅ Copy generated for pages")
