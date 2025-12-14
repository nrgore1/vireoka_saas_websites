import json

prompt = input("Describe the site: ")

site = {
  "site_id": "prompt-generated-site",
  "pages": ["Home", "Product", "About", "Contact"]
}

open("site.json","w").write(json.dumps(site, indent=2))
print("✅ site.json generated from prompt")
