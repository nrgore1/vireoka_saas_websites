import requests
import base64
import json
import re

WP_URL = "https://vireoka.com"
USERNAME = "nrgore1@gmail.com"
APP_PASSWORD = "YXfP 0R3N xH9R LKgT m1aq RbKo"

token = base64.b64encode(f"{USERNAME}:{APP_PASSWORD}".encode()).decode()
HEADERS = {
    "Authorization": f"Basic {token}",
    "Content-Type": "application/json"
}

KEYWORD_COMPONENT_MAP = {
    "agent": "[vireoka_agent_card name=\"AtmaSphere\" role=\"LLM Core\" tagline=\"Multi-agent reasoning.\"]",
    "pricing": "[vireoka_pricing]",
    "plan": "[vireoka_pricing]",
    "faq": "[vireoka_faq][vireoka_faq_item question=\"What is Vireoka?\"]A multi-agent platform.[/vireoka_faq_item][/vireoka_faq]",
    "feature": "[vireoka_feature_grid][vireoka_feature title=\"Multi-agent reasoning\"]AtmaSphere powers complex workflows.[/vireoka_feature][/vireoka_feature_grid]",
    "overview": "[vireoka_hero title=\"Welcome to Vireoka\" subtitle=\"AI Agents for everyone\" button=\"Join Waitlist\" url=\"/waitlist\"]"
}

def fetch_pages():
    pages = []
    page = 1
    while True:
        resp = requests.get(f"{WP_URL}/wp-json/wp/v2/pages?per_page=100&page={page}&context=edit", headers=HEADERS)
        if resp.status_code == 400:
            break
        resp.raise_for_status()
        batch = resp.json()
        if not batch:
            break
        pages.extend(batch)
        page += 1
    return pages

def classify_and_inject(content, title):
    new_content = content
    title_lower = title.lower()

    for keyword, component in KEYWORD_COMPONENT_MAP.items():
        if keyword in title_lower or keyword in content.lower():
            new_content += "\n\n" + component

    # Replace Elementor buttons
    new_content = new_content.replace(
        'class="elementor-button',
        'class="elementor-button vk-btn vk-btn-primary'
    )

    # Wrap sections
    new_content = re.sub(
        r'class="elementor-section([^"]*)"',
        r'class="elementor-section \1 vk-section-dark"',
        new_content
    )

    return new_content

def update_page(page):
    pid = page["id"]
    title = page["title"]["rendered"]
    raw = page["content"]["raw"]

    transformed = classify_and_inject(raw, title)

    if transformed == raw:
        print("SKIP:", title)
        return

    resp = requests.post(f"{WP_URL}/wp-json/wp/v2/pages/{pid}",
                         headers=HEADERS,
                         data=json.dumps({"content": transformed}))
    if resp.status_code in (200, 201):
        print("UPDATED:", title)
    else:
        print("ERROR:", title, resp.status_code, resp.text)

def main():
    pages = fetch_pages()
    print("Found", len(pages), "pages")
    for p in pages:
        update_page(p)

main()
