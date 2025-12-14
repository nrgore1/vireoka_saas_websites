import json

site = {
  "site_id": "ai-product",
  "pages": ["Home", "Features", "Pricing", "Contact"]
}

json.dump(site, open("site.json", "w"), indent=2)
print("✅ site.json generated")
