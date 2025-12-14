#!/usr/bin/env python3
import json, sys

if len(sys.argv) < 2:
    print("Usage: vire <site.json>")
    sys.exit(1)

spec = json.load(open(sys.argv[1]))

pages = spec.get("pages", [])
site_id = spec.get("site_id", "site")

print(f"✅ Site generated: {site_id}")
print("Pages:", ", ".join(pages))
