#!/bin/bash

PAGE_TITLE="Vireoka Home"
PAGE_SLUG="vireoka-home"
TEMPLATE_NAME="Vireoka Template 1"

echo "🔍 Looking for Template: $TEMPLATE_NAME..."

TEMPLATE_ID=$(wp post list \
    --post_type=elementor_library \
    --format=ids \
    --title="$TEMPLATE_NAME")

if [ -z "$TEMPLATE_ID" ]; then
    echo "❌ Elementor Template not found: $TEMPLATE_NAME"
    exit 1
fi

echo "✅ Template found: ID $TEMPLATE_ID"

# Create or update the page
PAGE_ID=$(wp post list \
    --post_type=page \
    --format=ids \
    --name="$PAGE_SLUG")

if [ -z "$PAGE_ID" ]; then
    echo "🆕 Creating new Vireoka Home page..."
    PAGE_ID=$(wp post create \
        --post_type=page \
        --post_title="$PAGE_TITLE" \
        --post_name="$PAGE_SLUG" \
        --post_status=publish \
        --porcelain)
else
    echo "♻️ Updating existing page ID $PAGE_ID..."
fi

echo "📝 Inserting Elementor Template into page meta…"

# Attach Elementor template to the page
wp post meta update $PAGE_ID _elementor_data \
    "{\"id\":\"$PAGE_ID\",\"elType\":\"page\",\"settings\":[],\"elements\":[{\"id\":\"template-block\",\"elType\":\"section\",\"settings\":{\"template_id\":$TEMPLATE_ID},\"elements\":[],\"isInner\":false}],\"settings\":[]}"

echo "➕ Appending Vireoka Home Builder section…"

# Append shortcode after template
wp post update $PAGE_ID --post_content="[vireoka_home style=\"F\" product=\"Vireoka Home\"]"

echo "🏠 Setting as Homepage..."
wp option update show_on_front page
wp option update page_on_front $PAGE_ID

echo "🎉 DONE! Visit: https://vireoka.com/"
