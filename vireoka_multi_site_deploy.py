import base64, json, requests, time, sys
SITES = [
    {
        "name": "Vireoka Corporate",
        "url": "https://vireoka.com",
        "username": "admin",
        "app_password": "APP_PASSWORD_1",
        "variant": "A",
    },
    {
        "name": "AtmaSphere Dev Hub",
        "url": "https://developers.vireoka.com",
        "username": "admin",
        "app_password": "APP_PASSWORD_2",
        "variant": "B",
    },
    {
        "name": "FinOps Hub",
        "url": "https://finops.vireoka.com",
        "username": "admin",
        "app_password": "APP_PASSWORD_3",
        "variant": "C",
    },
    {
        "name": "Consumer Experiences",
        "url": "https://experiences.vireoka.com",
        "username": "admin",
        "app_password": "APP_PASSWORD_4",
        "variant": "D",
    },
]
def trigger_site(site):
    name = site["name"]
    url = site["url"].rstrip("/")
    user = site["username"]
    app_pw = site["app_password"]
    variant = site["variant"].upper()
print(f"\n=== Deploying {name} ({variant}) ===")
token = base64.b64encode(f"{user}:{app_pw}".encode()).decode()
headers = {
        "Authorization": f"Basic {token}",
        "Content-Type": "application/json",
    }
endpoint = f"{url}/wp-json/vireoka/v1/generate"
    payload = {"variant": variant}
try:
        resp = requests.post(endpoint, headers=headers, json=payload, timeout=45)
    except Exception as e:
        print(f"[ERROR] Network issue: {e}")
        return
if resp.status_code not in (200, 201):
        print(f"[HTTP ERROR] {resp.status_code} => {resp.text}")
        return
data = resp.json()
    if not data.get("ok"):
        print(f"[AGENT ERROR] {data}")
        return
print(f"[OK] Variant {variant} deployed for {name}.")
    for key, pid in data.get("pages", {}).items():
        print(f"  - {key}: ID {pid}")
def main():
    for site in SITES:
        trigger_site(site)
        time.sleep(3)
if __name__ == "__main__":
    main()
