#!/bin/bash
set -e

echo "=========================================="
echo "🔧 VIREOKA CONFIG AUTO-FIX v1.0"
echo "=========================================="

CONFIG="vireoka-tools/vconfig.sh"

if [ ! -f "$CONFIG" ]; then
    echo "❌ ERROR: $CONFIG not found!"
    exit 1
fi

echo "📝 Checking vconfig.sh..."

# ----------------------------------------------------------
# 1. Ensure required folders exist
# ----------------------------------------------------------

LOCAL_ROOT="/mnt/c/Projects2025/vireoka_website/vireoka_local"
LOCAL_PLUGINS="$LOCAL_ROOT/wp-content/plugins"
LOCAL_THEMES="$LOCAL_ROOT/wp-content/themes"
LOCAL_UPLOADS="$LOCAL_ROOT/wp-content/uploads"

mkdir -p "$LOCAL_ROOT" "$LOCAL_PLUGINS" "$LOCAL_THEMES" "$LOCAL_UPLOADS"

echo "✔ Ensured local WP structure exists."

# ----------------------------------------------------------
# 2. Fix RSYNC command (remove broken quoting)
# ----------------------------------------------------------

echo "🔍 Fixing RSYNC command..."

# Remove old RSYNC lines
sed -i '/RSYNC=/d' "$CONFIG"
sed -i '/RSYNC_CMD=/d' "$CONFIG"

# Add clean commands
cat << 'EOF' >> "$CONFIG"

# --- FIXED RSYNC COMMANDS ---
RSYNC_CMD="ssh -p $REMOTE_PORT"
RSYNC="rsync -avz --delete -e \"$RSYNC_CMD\""
EOF

echo "✔ RSYNC command repaired."

# ----------------------------------------------------------
# 3. Validate SSH config
# ----------------------------------------------------------

echo "🔍 Testing SSH connection..."

if ssh -o BatchMode=yes -p 65002 "$REMOTE_USER@$REMOTE_HOST" "echo ok" >/dev/null 2>&1; then
    echo "✔ SSH is working."
else
    echo "⚠️ SSH requires password OR key."
    echo "   You may install a key with:"
    echo "   ssh-copy-id -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST"
fi

# ----------------------------------------------------------
# 4. Normalize remote paths
# ----------------------------------------------------------

echo "🔍 Fixing remote WP paths..."

sed -i 's|public_html/wp-content/plugins$|public_html/wp-content/plugins/|g' "$CONFIG"
sed -i 's|public_html/wp-content/themes$|public_html/wp-content/themes/|g' "$CONFIG"
sed -i 's|public_html/wp-content/uploads$|public_html/wp-content/uploads/|g' "$CONFIG"

echo "✔ Remote paths normalized."

# ----------------------------------------------------------
# 5. Validate two-way sync mode defaults
# ----------------------------------------------------------

echo "🔍 Setting sync defaults..."

grep -q "SYNC_MODE=" "$CONFIG" || echo 'SYNC_MODE="two-way"' >> "$CONFIG"

echo "✔ SYNC_MODE ensured."

# ----------------------------------------------------------
# 6. Summary
# ----------------------------------------------------------

echo ""
echo "=========================================="
echo "🎉 AUTO-FIX COMPLETE"
echo "=========================================="
echo "Your vconfig.sh is now clean and ready."
echo "Run sync with:"
echo ""
echo "   bash vireoka-tools/vsync.sh plugins"
echo ""
