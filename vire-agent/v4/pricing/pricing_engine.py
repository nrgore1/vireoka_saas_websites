#!/usr/bin/env python3
import json, sys, datetime

"""
Deterministic tier builder.
Input: product_id, complexity (1-5), target (consumer|pro|enterprise)
Output: pricing.json
"""

def clamp(n, lo, hi): return max(lo, min(hi, n))

def build(product_id, complexity, target):
    complexity = clamp(int(complexity), 1, 5)
    target = target.lower().strip()

    # Base pricing by target
    if target == "consumer":
        base = 9
        step = 6
    elif target == "pro":
        base = 29
        step = 20
    else:
        target = "enterprise"
        base = 99
        step = 60

    # Complexity multiplier
    mult = 1.0 + (complexity - 1) * 0.22

    tiers = [
        {
            "name": "Starter",
            "price_monthly": int(round(base * mult)),
            "features": [
                "Core workflows",
                "Standard support",
                "Single workspace"
            ],
            "limits": {"projects": 3 * complexity, "seats": 1}
        },
        {
            "name": "Pro",
            "price_monthly": int(round((base + step) * mult)),
            "features": [
                "Everything in Starter",
                "Automations",
                "Advanced analytics",
                "Priority support"
            ],
            "limits": {"projects": 10 * complexity, "seats": 5}
        },
        {
            "name": "Enterprise",
            "price_monthly": "Contact Sales",
            "features": [
                "SAML/SSO",
                "Audit logs",
                "Custom SLAs",
                "Dedicated onboarding",
                "Private deployment options"
            ],
            "limits": {"projects": "Unlimited", "seats": "Unlimited"}
        }
    ]

    return {
        "product_id": product_id,
        "target": target,
        "complexity": complexity,
        "generated_at": datetime.datetime.utcnow().isoformat() + "Z",
        "tiers": tiers
    }

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: pricing_engine.py <product_id> <complexity 1-5> <consumer|pro|enterprise>")
        sys.exit(1)

    product_id, complexity, target = sys.argv[1], sys.argv[2], sys.argv[3]
    data = build(product_id, complexity, target)
    out = "vire-agent/export/pricing.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print("✅ Pricing generated:", out)
