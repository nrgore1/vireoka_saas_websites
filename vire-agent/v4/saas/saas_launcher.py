#!/usr/bin/env python3
import json, sys, datetime, re

def slugify(s):
    s = s.strip().lower()
    s = re.sub(r"[^a-z0-9\\s-]", "", s)
    s = re.sub(r"\\s+", "-", s)
    return s

"""
Creates tenant-ready spec:
- site_id = product + tenant
- pages include: Home, Pricing, Demo, Privacy, Terms
"""

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: saas_launcher.py <product_name> <tenant_name> <tone>")
        sys.exit(1)

    product_name = sys.argv[1]
    tenant_name = sys.argv[2]
    tone = sys.argv[3]

    product_slug = slugify(product_name)
    tenant_slug = slugify(tenant_name)

    site = {
        "site_id": f"{product_slug}-{tenant_slug}",
        "product_name": product_name,
        "tenant_name": tenant_name,
        "tone": tone,
        "audience": "early adopters, founders, and enterprise evaluators",
        "keywords": [
            "AI agent frameworks",
            "enterprise-ready platform",
            "secure AI workflows"
        ],
        "pages": [
            "Home",
            "Features",
            "Pricing",
            "Request Demo",
            "Privacy",
            "Terms"
        ],
        "generated_at": datetime.datetime.utcnow().isoformat() + "Z"
    }

    out = "vire-agent/v3/outputs/site.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(site, f, indent=2)
    print("✅ Tenant site.json written:", out)
