#!/usr/bin/env python3
"""
Vireoka Elementor Orchestrator v3
---------------------------------
- Hostinger + Elementor-compatible (no meta in list endpoint)
- Updates Elementor layouts and converts classic pages to Elementor
- Adds:
    * Hero (via [vireoka_hero] shortcode)
    * Body section
    * Products strip (6 product cards) for key pages
    * CTA section (via [vireoka_cta])
- Idempotent:
    * Does NOT duplicate hero / CTA / products on re-run
- Conservative HTML cleanup:
    * elementor-button -> vk-btn vk-btn-primary
    * elementor-section -> vk-section-dark
"""

import requests
import base64
import json
import re

# ============================================================
# CONFIGURATION – EDIT THESE
# ============================================================

WP_URL = "https://vireoka.com"

USERNAME = "nrgore1@gmail.com"
APP_PASSWORD = "YXfP 0R3N xH9R LKgT m1aq RbKo"

# Optional AtmaSphere LLM integration
USE_ATMASPHERE = False               # set True when your API is ready
ATMA_URL = "https://api.atmasphere.yourdomain.com/generate"
ATMA_API_KEY = "YOUR_ATMASPHERE_KEY"

# Pages we do NOT auto-convert to Elementor
SKIP_ELEMENTOR_CONVERSION_TITLES = {"Blog"}

# Pages that SHOULD get a products strip
PRODUCT_STRIP_TITLES = {"Home", "Vireoka Home", "Products"}


# ============================================================
# AUTH HEADERS
# ============================================================

token = base64.b64encode(f"{USERNAME}:{APP_PASSWORD}".encode()).decode()

HEADERS = {
    "Authorization": f"Basic {token}",
    "Content-Type": "application/json"
}


# ============================================================
# CONSERVATIVE HTML TRANSFORM
# ============================================================

def conservative_html_cleanup(html: str) -> str:
    """
    Very conservative transformation:
    - Add vk-btn-primary to elementor buttons
    - Add vk-section-dark class to elementor sections
    """
    if not html:
        return html

    new = html

    new = new.replace(
        'class="elementor-button ',
        'class="elementor-button vk-btn vk-btn-primary '
    ).replace(
        'class="elementor-button"',
        'class="elementor-button vk-btn vk-btn-primary"'
    )

    new = re.sub(
        r'class="elementor-section([^"]*)"',
        r'class="elementor-section\1 vk-section-dark"',
        new
    )

    return new


# ============================================================
# FETCH PAGES (NO META HERE)
# ============================================================

def fetch_pages():
    pages = []
    page = 1

    while True:
        url = f"{WP_URL}/wp-json/wp/v2/pages?per_page=100&page={page}&context=edit"
        resp = requests.get(url, headers=HEADERS)
        if resp.status_code == 400:
            # "page number larger than available" – normal end
            break
        if resp.status_code >= 400:
            print("Error fetching pages:", resp.status_code, resp.text[:200])
            break

        batch = resp.json()
        if not batch:
            break

        pages.extend(batch)
        page += 1

    return pages


# ============================================================
# LOAD ELEMENTOR DATA FOR A SINGLE PAGE
# ============================================================

def load_elementor_data(page_id):
    """
    WordPress allows meta access on /pages/<id>?context=edit
    even when it is blocked on list endpoint.
    """
    url = f"{WP_URL}/wp-json/wp/v2/pages/{page_id}?context=edit"
    resp = requests.get(url, headers=HEADERS)

    if resp.status_code >= 400:
        print(f"  ! Could not fetch meta for page {page_id}: {resp.status_code}")
        return "", None

    data = resp.json()
    meta = data.get("meta", {})
    raw_html = data.get("content", {}).get("raw", "") or ""

    raw_elementor = meta.get("_elementor_data")
    if not raw_elementor:
        return raw_html, None

    try:
        if isinstance(raw_elementor, str):
            return raw_html, json.loads(raw_elementor)
        return raw_html, raw_elementor
    except json.JSONDecodeError:
        print("  ! Malformed Elementor JSON")
        return raw_html, None


# ============================================================
# ATMASPHERE COPY (OPTIONAL)
# ============================================================

def atmasphere_copy(title, html):
    fallback = {
        "subtitle": "Six breakthrough products. One shared intelligence.",
        "body": (
            f"{title} is part of Vireoka’s AI Agent ecosystem, combining multi-agent reasoning, "
            "aligned decision systems, and production-grade automation."
        ),
        "cta_title": "Partner with Vireoka",
        "cta_text": "Founders, CTOs, and educators: bring multi-agent AI into your products and workflows.",
        "cta_button_text": "Talk to Us"
    }

    if not USE_ATMASPHERE:
        return fallback

    try:
        payload = {
            "title": title,
            "html": html,
            "instruction": (
                "Generate JSON with fields: subtitle, body, cta_title, cta_text, cta_button_text. "
                "Tone: confident, concise, visionary."
            )
        }
        headers = {"Content-Type": "application/json"}
        headers["Authorization"] = f"Bearer {ATMA_API_KEY}"

        resp = requests.post(ATMA_URL, headers=headers, json=payload, timeout=20)
        if resp.status_code >= 400:
            print("  ! AtmaSphere error:", resp.status_code, resp.text[:200])
            return fallback

        data = resp.json()
        for k, v in fallback.items():
            data.setdefault(k, v)
        return data

    except Exception as e:
        print("  ! AtmaSphere offline, using fallback:", e)
        return fallback


# ============================================================
# ELEMENTOR SECTION BUILDERS
# ============================================================

def section_hero(copy):
    shortcode = (
        f'[vireoka_hero title="Vireoka — The AI Agent Company" '
        f'subtitle="{copy["subtitle"]}" '
        f'button="Join Waitlist" url="/contact"]'
    )
    return {
        "id": "vk-section-hero",
        "elType": "section",
        "settings": {
            "content_width": "boxed",
            "background_background": "gradient",
            "background_color": "#020617",
            "background_color_b": "#111827",
            "_css_classes": "vk-section-dark vireoka-hero",
            "padding": {
                "unit": "px",
                "top": "120",
                "bottom": "120",
                "isLinked": False
            }
        },
        "elements": [
            {
                "id": "vk-col-hero",
                "elType": "column",
                "settings": {"_column_size": 100},
                "elements": [
                    {
                        "id": "vk-hero-widget",
                        "elType": "widget",
                        "widgetType": "shortcode",
                        "settings": {"shortcode": shortcode},
                        "elements": []
                    }
                ]
            }
        ]
    }


def section_body(copy):
    html = f'<p>{copy["body"]}</p>'
    return {
        "id": "vk-section-body",
        "elType": "section",
        "settings": {
            "content_width": "boxed",
            "background_background": "classic",
            "background_color": "#020617",
            "_css_classes": "vk-section-dark",
            "padding": {
                "unit": "px",
                "top": "60",
                "bottom": "60",
                "isLinked": False
            }
        },
        "elements": [
            {
                "id": "vk-col-body",
                "elType": "column",
                "settings": {"_column_size": 100},
                "elements": [
                    {
                        "id": "vk-body-widget",
                        "elType": "widget",
                        "widgetType": "text-editor",
                        "settings": {"editor": html},
                        "elements": []
                    }
                ]
            }
        ]
    }


def section_products():
    """
    Uses your existing [vireoka_feature_grid]/[vireoka_feature] shortcodes
    to render a 3x2 product grid.
    """
    shortcode = (
        '[vireoka_feature_grid]'
        '[vireoka_feature title="AtmaSphere LLM"]Core multi-agent reasoning engine.[/vireoka_feature]'
        '[vireoka_feature title="Communication Suite"]AI coaching for debates, pitches, and leadership.[/vireoka_feature]'
        '[vireoka_feature title="Dating Platform Builder"]Niche, curated dating communities.[/vireoka_feature]'
        '[vireoka_feature title="Memoir Studio"]AI-designed memoirs and coffee-table books.[/vireoka_feature]'
        '[vireoka_feature title="FinOps AI"]Autonomous cloud & AI cost optimization.[/vireoka_feature]'
        '[vireoka_feature title="Quantum-Secure Stablecoin"]Stablecoin architecture designed for a post-quantum world.[/vireoka_feature]'
        '[/vireoka_feature_grid]'
    )
    return {
        "id": "vk-section-products",
        "elType": "section",
        "settings": {
            "content_width": "boxed",
            "background_background": "classic",
            "background_color": "#020617",
            "_css_classes": "vk-section-dark vireoka-products-strip",
            "padding": {
                "unit": "px",
                "top": "60",
                "bottom": "60",
                "isLinked": False
            }
        },
        "elements": [
            {
                "id": "vk-col-products",
                "elType": "column",
                "settings": {"_column_size": 100},
                "elements": [
                    {
                        "id": "vk-products-widget",
                        "elType": "widget",
                        "widgetType": "shortcode",
                        "settings": {"shortcode": shortcode},
                        "elements": []
                    }
                ]
            }
        ]
    }


def section_cta(copy):
    shortcode = (
        f'[vireoka_cta title="{copy["cta_title"]}" '
        f'text="{copy["cta_text"]}" '
        f'button_text="{copy["cta_button_text"]}" '
        f'button_url="/contact"]'
    )
    return {
        "id": "vk-section-cta",
        "elType": "section",
        "settings": {
            "content_width": "boxed",
            "background_background": "gradient",
            "background_color": "#111827",
            "background_color_b": "#020617",
            "_css_classes": "vk-section-dark",
            "padding": {
                "unit": "px",
                "top": "80",
                "bottom": "80",
                "isLinked": False
            }
        },
        "elements": [
            {
                "id": "vk-col-cta",
                "elType": "column",
                "settings": {"_column_size": 100},
                "elements": [
                    {
                        "id": "vk-cta-widget",
                        "elType": "widget",
                        "widgetType": "shortcode",
                        "settings": {"shortcode": shortcode},
                        "elements": []
                    }
                ]
            }
        ]
    }


def build_full_layout(copy, include_products: bool) -> list:
    layout = [section_hero(copy), section_body(copy)]
    if include_products:
        layout.append(section_products())
    layout.append(section_cta(copy))
    return layout


# ============================================================
# ELEMENTOR JSON TRANSFORM
# ============================================================

def transform_elementor_node(node):
    # Sections → add vk-section-dark
    if node.get("elType") == "section":
        node.setdefault("settings", {})
        cls = node["settings"].get("_css_classes", "")
        if "vk-section-dark" not in cls:
            node["settings"]["_css_classes"] = (cls + " vk-section-dark").strip()

    # Button widgets → add vk-btn-primary
    if node.get("widgetType") == "button":
        node.setdefault("settings", {})
        btn_cls = node["settings"].get("button_css_classes", "")
        if "vk-btn-primary" not in btn_cls:
            node["settings"]["button_css_classes"] = (btn_cls + " vk-btn-primary").strip()

    # Recurse
    if "elements" in node and isinstance(node["elements"], list):
        for child in node["elements"]:
            transform_elementor_node(child)


def layout_contains(layout, token: str) -> bool:
    try:
        blob = json.dumps(layout)
    except Exception:
        blob = str(layout)
    return token in blob


def ensure_sections(layout, copy, include_products: bool):
    """
    Ensure hero / products / CTA exist once.
    """
    # Hero
    if not layout_contains(layout, "vireoka_hero"):
        layout.insert(0, section_hero(copy))

    # Products strip
    if include_products and not layout_contains(layout, "vireoka_feature_grid"):
        # Insert after hero if present
        if layout_contains(layout, "vk-section-hero"):
            layout.insert(1, section_products())
        else:
            layout.append(section_products())

    # CTA
    if not layout_contains(layout, "vireoka_cta"):
        layout.append(section_cta(copy))

    return layout


# ============================================================
# WORDPRESS UPDATE
# ============================================================

def wp_update_page(page_id, payload):
    url = f"{WP_URL}/wp-json/wp/v2/pages/{page_id}?context=edit"
    return requests.post(url, headers=HEADERS, data=json.dumps(payload))


# ============================================================
# PROCESS SINGLE PAGE
# ============================================================

def process_page(page):
    pid = page["id"]
    title = page["title"]["rendered"]
    slug = page.get("slug", "")

    print(f"\nProcessing page {pid}: {title}")

    raw_html, elementor_json = load_elementor_data(pid)

    include_products = title in PRODUCT_STRIP_TITLES or slug in {"home", "vireoka-home", "products"}

    # If not Elementor yet → convert
    if elementor_json is None:
        print(" - Non-Elementor page")

        if title in SKIP_ELEMENTOR_CONVERSION_TITLES:
            print("   SKIP conversion for:", title)
            cleaned = conservative_html_cleanup(raw_html)
            if cleaned != raw_html:
                resp = wp_update_page(pid, {"content": cleaned})
                if resp.status_code in (200, 201):
                    print("   ✔ Updated classic HTML")
                else:
                    print("   ❌ ERROR updating classic HTML:", resp.status_code, resp.text[:200])
            return

        print("   → Converting to Elementor layout")
        copy = atmasphere_copy(title, raw_html)
        layout = build_full_layout(copy, include_products)

        payload = {
            "content": "",
            "meta": {
                "_elementor_data": json.dumps(layout),
                "_elementor_edit_mode": "builder",
                "_wp_page_template": "elementor_canvas"
            }
        }
        resp = wp_update_page(pid, payload)
        if resp.status_code in (200, 201):
            print(" ✔ Converted to Elementor")
        else:
            print(" ❌ ERROR converting:", resp.status_code, resp.text[:200])
        return

    # Already Elementor → tweak + ensure sections
    print(" - Elementor page")

    copy = atmasphere_copy(title, raw_html)

    for node in elementor_json:
        transform_elementor_node(node)

    layout = ensure_sections(elementor_json, copy, include_products)

    payload = {
        "meta": {
            "_elementor_data": json.dumps(layout)
        }
    }
    resp = wp_update_page(pid, payload)
    if resp.status_code in (200, 201):
        print(" ✔ Updated Elementor layout")
    else:
        print(" ❌ ERROR updating Elementor layout:", resp.status_code, resp.text[:200])

    # Also lightly clean underlying HTML (for non-Elementor viewers)
    cleaned = conservative_html_cleanup(raw_html)
    if cleaned != raw_html:
        resp = wp_update_page(pid, {"content": cleaned})
        if resp.status_code in (200, 201):
            print(" ✔ Updated underlying HTML")
        else:
            print(" ❌ ERROR updating underlying HTML:", resp.status_code, resp.text[:200])


# ============================================================
# MAIN
# ============================================================

def main():
    pages = fetch_pages()
    print(f"Found {len(pages)} pages")

    for p in pages:
        process_page(p)

    print("\nDONE.")


if __name__ == "__main__":
    main()
