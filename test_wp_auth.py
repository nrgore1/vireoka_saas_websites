import requests, base64

WP_URL = "https://vireoka.com"
USERNAME = "nrgore1@gmail.com"
APP_PASSWORD = "YXfP 0R3N xH9R LKgT m1aq RbKo"

token = base64.b64encode(f"{USERNAME}:{APP_PASSWORD}".encode()).decode()

resp = requests.get(
    WP_URL + "/wp-json/wp/v2/users/me",
    headers={"Authorization": f"Basic {token}"}
)

print(resp.status_code)
print(resp.text)
