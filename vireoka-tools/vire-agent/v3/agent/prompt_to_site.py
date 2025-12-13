#!/usr/bin/env python3
import json, sys, datetime

if len(sys.argv) < 3:
    print("Usage: prompt_to_site.py <preset.json> <product_name>")
    sys.exit(1)

preset = json.load(open(sys.argv[1]))
product_name = sys.argv[2]

site = {
    "site_id": product_name.lower().replace(" ", "-"),
    "product_name": product_name,
    "tone": preset.get("tone", "neural-luxe"),
    "audience": preset.get("audience"),
    "keywords": preset.get("keywords"),
    "pages": preset.get("pages"),
    "generated_at": datetime.datetime.utcnow().isoformat() + "Z"
}

out = "vire-agent/v3/outputs/site.json"
json.dump(site, open(out,"w"), indent=2)
print("✅ site.json generated:", out)
