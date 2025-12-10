import requests
import base64
import sys

# === CONFIG === Needs to put passsword in config file
WP_BASE_URL = "https://vireoka.com"  # no trailing slash
WP_USERNAME = "nrgore1@gmail.com"
WP_APP_PASSWORD = "YXfP0R3NxH9RLKgTm1aqRbKo"  # 24-char string from WP

# Use basic auth with application password
auth_str = f"{WP_USERNAME}:{WP_APP_PASSWORD}"
AUTH_HEADER = base64.b64encode(auth_str.encode("utf-8")).decode("utf-8")
HEADERS = {
    "Authorization": f"Basic {AUTH_HEADER}",
    "Content-Type": "application/json"
}


def fetch_pages():
    pages = []
    page = 1
    while True:
        url = f"{WP_BASE_URL}/wp-json/wp/v2/pages?per_page=100&page={page}&context=edit"
        resp = requests.get(url, headers=HEADERS)
        if resp.status_code == 400:
            # no more pages
            break
        resp.raise_for_status()
        batch = resp.json()
        if not batch:
            break
        pages.extend(batch)
        page += 1
    return pages


def transform_content(html: str) -> str:
    """
    Very conservative transformation:
    - Add vk-btn-primary to elementor buttons
    - Add vk-section-dark class to <body> wrappers used by some builders
    You can extend this safely for more patterns.
    """

    if not html:
        return html

    new_html = html

    # 1) Elementor buttons: add vk-btn-primary
    new_html = new_html.replace(
        'class="elementor-button ',
        'class="elementor-button vk-btn vk-btn-primary '
    ).replace(
        'class="elementor-button"',
        'class="elementor-button vk-btn vk-btn-primary"'
    )

    # 2) Add vk-section-dark to common wrapper sections
    new_html = new_html.replace(
        'class="elementor-section',
        'class="elementor-section vk-section-dark'
    )

    return new_html


def update_page(page_obj):
    page_id = page_obj["id"]
    title = page_obj["title"]["rendered"]
    raw_content = page_obj["content"]["raw"]

    new_content = transform_content(raw_content)

    if new_content == raw_content:
        print(f"[SKIP] Page {page_id} – {title}: no changes")
        return

    url = f"{WP_BASE_URL}/wp-json/wp/v2/pages/{page_id}"
    resp = requests.post(
        url,
        headers=HEADERS,
        json={"content": new_content}
    )
    if resp.status_code in (200, 201):
        print(f"[OK] Updated page {page_id} – {title}")
    else:
        print(f"[ERROR] Page {page_id} – {title}: {resp.status_code} {resp.text}")


def main():
    print("Fetching pages...")
    pages = fetch_pages()
    print(f"Found {len(pages)} pages")

    for p in pages:
        update_page(p)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("Fatal error:", e)
        sys.exit(1)
