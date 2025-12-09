import base64, csv, json, requests, time
CSV_FILE = "sites.csv"
def trigger_site(row):
  name = row["name"]
  url = row["url"].rstrip("/")
  user = row["username"]
  app_pw = row["app_password"]
  variant = row["variant"].upper()
print(f"\n=== Deploying {name} ({url}) as {variant} ===")
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
  with open(CSV_FILE, newline='') as f:
    reader = csv.DictReader(f)
    for row in reader:
      trigger_site(row)
      time.sleep(2)
if __name__ == "__main__":
  main()
