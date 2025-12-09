import base64
import json
import sys
import requests
WP_URL = "https://vireoka.com"  # change if needed, no trailing slash
WP_USER = "your-wp-username"    # e.g. admin
WP_APP_PASSWORD = "your-app-password-here"  # application password
def trigger_generation(variant: str):
    variant = variant.upper()
    if variant not in ("A", "B", "C", "D"):
        print("Invalid variant. Use A, B, C, or D.")
        sys.exit(1)
auth_str = f"{WP_USER}:{WP_APP_PASSWORD}"
    token = base64.b64encode(auth_str.encode("utf-8")).decode("utf-8")
headers = {
        "Authorization": f"Basic {token}",
        "Content-Type": "application/json",
    }
url = f"{WP_URL}/wp-json/vireoka/v1/generate"
    payload = {"variant": variant}
print(f"Triggering Vireoka Website Creator for variant {variant} at {url} ...")
    resp = requests.post(url, headers=headers, data=json.dumps(payload))
if resp.status_code not in (200, 201):
        print("Error:", resp.status_code, resp.text)
        sys.exit(1)
data = resp.json()
    if not data.get("ok"):
        print("Error from server:", data)
    else:
        print("Success. Generated pages:")
        for key, pid in data.get("pages", {}).items():
            print(f"  {key}: page ID {pid}")
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python vireoka_site_agent_trigger.py <variant>")
        print("Example: python vireoka_site_agent_trigger.py A")
        sys.exit(1)
variant_arg = sys.argv[1]
    trigger_generation(variant_arg)
