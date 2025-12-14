#!/usr/bin/env python3
import json, pathlib

site = json.load(open("vire-agent/v3/outputs/site.json"))

schema = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": site["product_name"],
  "applicationCategory": "AIApplication",
  "keywords": site["keywords"],
  "author": {
    "@type": "Person",
    "name": "Narendra Gore"
  }
}

out = pathlib.Path("vire-agent/export/schema.json")
out.write_text(json.dumps(schema, indent=2))
print("✅ Schema generated:", out)
