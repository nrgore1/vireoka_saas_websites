#!/usr/bin/env python3
import requests
import base64
import json
import re

# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------

WP_URL = "https://vireoka.com"
USERNAME = "nrgore1@gmail.com"
APP_PASSWORD = "YXfP 0R3N xH9R LKgT m1aq RbKo".replace(" ", "")  # Removes accidental spaces

token = base64.b64encode(f"{USERNAME}:{APP_PASSWORD}".encode()).decode()

HEADERS = {
    "Authorization": f"Basic {token}",
    "Content-Type": "application/json"
}

# ---------------------------------------------------------
# SIMPLE VIREOKA COMPONENT INJECTIONS BASED ON KEYWORDS
# ---------------------------------------------------------

KEYWORD_COMPONENT_MAP = {
    "agent": "[vireoka_agent_card name=\"AtmaSphere\" role=\"LLM Core\" tagline=\"Multi-agent reasoning.\"]",
    "pricing": "[vireoka_pricing]",
    "plan": "[vireoka_pricing]",
    "faq": "[vireoka_faq][vireoka_faq_item question=\"What is Vireoka?\"]A multi-agent platform.[/vireoka_faq_item][/vireoka_faq]",
    "feature": "[vireoka_feature_grid][vireoka_feature title=\"Multi-agent reasoning\"]AtmaSphere powers complex workflows.[/vireoka_feature][/vireoka_feature_grid]",
    "overview": "[vireoka_hero title=\"Welcome to Vireoka\" subtitle=\"AI Agents for everyone\" button=\"Join Waitlist\" url=\"/waitlist\"]"
}


# ---------------------------------------------------------
# VERY CONSERVATIVE TRANSFORMATIONS REQUIRED
# - Add vk-btn-primary to elementor buttons
# - Add vk-section-dark class to elementor sections
# ---------------------------------------------------------

def conservative_html_cleanup(html: str) -> str:
    """
    Very conservative transformation:
    - Add vk-btn-primary to elementor buttons
    - Add vk-section-dark class to <section> wrappers
    - Very safe regex replacements only
    """
    # Add class to Elementor buttons
    html = html.replace(
        'class="elementor-button',
        'class="elementor-button vk-btn-primary'
    )

    # Add section-dark style
    html = re.sub(
        r'class="elementor-section([^"]*)"',
        r'class="elementor-section\1 vk-section-dark"',
        html
    )

    return html


# ---------------------------------------------------------
# FETCH WORDPRESS PAGES
# ---------------------------------------------------------

def fetch_pages():
    pages = []
    page = 1
    while True:
        url = f"{WP_URL}/wp-json/wp/v2/pages?per_page=100&page={page}&context=edit&_fields=id,title,content,meta"
        resp = requests.get(url, headers=HEADERS)

        if resp.status_code in (400, 401):
            break

        resp.raise_for_status()

        batch = resp.json()
        if not batch:
            break

        pages.extend(batch)
        page += 1

    return pages


# ---------------------------------------------------------
# PARSE ELEMENTOR JSON
# ---------------------------------------------------------

def load_elementor_json(meta):
    if "_elementor_data" not in meta:
        return None

    try:
        raw = meta["_elementor_data"]
        if isinstance(raw, str):
            return json.loads(raw)
        return raw
    except json.JSONDecodeError:
        print("ERROR: malformed Elementor JSON")
        return None


# ---------------------------------------------------------
# APPLY CONSERVATIVE TRANSFORMATIONS TO WIDGETS
# ---------------------------------------------------------

def transform_elementor_node(node):
    """
    Recursively adjusts Elementor layout:
    - Add vk-btn-primary to buttons
    - Add vk-section-dark to sections
    - Safe modifications only
    """
    # Add classes safely when appropriate
    if "elType" in node and node["elType"] == "section":
        node.setdefault("settings", {})
        node["settings"].setdefault("_css_classes", "")
        if "vk-section-dark" not in node["settings"]["_css_classes"]:
            node["settings"]["_css_classes"] += " vk-section-dark"

    # Elementor button widget
    if node.get("widgetType") == "button":
        node.setdefault("settings", {})
        existing = node["settings"].get("button_css_classes", "")
        if "vk-btn-primary" not in existing:
            node["settings"]["button_css_classes"] = (existing + " vk-btn-primary").strip()

    # Recurse into children
    if "elements" in node and isinstance(node["elements"], list):
        for child in node["elements"]:
            transform_elementor_node(child)


# ---------------------------------------------------------
# INJECT SHORTCODES BASED ON PAGE CONTENT
# ---------------------------------------------------------

def inject_components_into_raw_content(content, title):
    new_content = content or ""
    title_lower = (title or "").lower()

    # Inject based on keywords
    for keyword, component in KEYWORD_COMPONENT_MAP.items():
        if keyword in title_lower or keyword in new_content.lower():
            new_content += "\n\n" + component

    # Then apply conservative modifications
    new_content = conservative_html_cleanup(new_content)
    return new_content


# ---------------------------------------------------------
# UPDATE PAGE
# ---------------------------------------------------------

def update_page(page):
    pid = page["id"]
    title = page["title"]["rendered"]

    raw = page["content"].get("raw", "")
    meta = page.get("meta", {})

    print(f"\nProcessing page: {title} (ID={pid})")

    # Load Elementor JSON
    elementor_json = load_elementor_json(meta)

    # If Elementor page → update layout JSON
    if elementor_json:
        print(" - Elementor page detected → transforming JSON...")

        # Transform JSON layout
        for root in elementor_json:
            transform_elementor_node(root)

        payload = {
            "meta": {
                "_elementor_data": json.dumps(elementor_json)
            }
        }

        resp = requests.post(
            f"{WP_URL}/wp-json/wp/v2/pages/{pid}?context=edit",
            headers=HEADERS,
            data=json.dumps(payload)
        )

        if resp.status_code in (200, 201):
            print(" ✔ Elementor JSON updated.")
        else:
            print(" ❌ ERROR updating Elementor JSON:", resp.status_code, resp.text)

    else:
        # Not an Elementor page → modify raw content
        print(" - NON-Elementor page → modifying content field.")

        transformed_raw = inject_components_into_raw_content(raw, title)

        if transformed_raw == raw:
            print("   SKIP: No changes detected.")
            return

        resp = requests.post(
            f"{WP_URL}/wp-json/wp/v2/pages/{pid}",
            headers=HEADERS,
            data=json.dumps({"content": transformed_raw})
        )

        if resp.status_code in (200, 201):
            print(" ✔ Classic page content updated.")
        else:
            print(" ❌ ERROR:", resp.status_code, resp.text)


# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

def main():
    pages = fetch_pages()
    print(f"Found {len(pages)} pages.\n")

    for page in pages:
        update_page(page)

    print("\nDONE.")


if __name__ == "__main__":
    main()
