#!/bin/bash
set -e
# === EDIT THESE FOR YOUR SERVER ===
HOST="your-hostinger-ip-or-host"
USER="your-ssh-username"
SSH_PORT=22
# Base path where your sites live (e.g. public_html if each site is under subfolder)
REMOTE_BASE="/home/uXXXXXXX"
# Global DB root or management user (if allowed)
DB_HOST="localhost"
DB_ROOT_USER="db_root_user"
DB_ROOT_PASS="db_root_password"
# Per-site config (add more as needed)
# Format: "folder;url;db_name;db_user;db_pass;site_title;admin_user;admin_email"
SITES=(
  "public_html;https://vireoka.com;vireoka_main;vireoka_main_user;StrongPass1;Vireoka;admin;admin@vireoka.com"
  "developers;https://developers.vireoka.com;vireoka_dev;vireoka_dev_user;StrongPass2;AtmaSphere Dev;devadmin;dev@vireoka.com"
  "finops;https://finops.vireoka.com;vireoka_finops;vireoka_finops_user;StrongPass3;Vireoka FinOps;finadmin;finops@vireoka.com"
  "experiences;https://experiences.vireoka.com;vireoka_exp;vireoka_exp_user;StrongPass4;Vireoka Experiences;expadmin;experiences@vireoka.com"
)
# === SCRIPT ===
for SITE in "${SITES[@]}"; do
  IFS=';' read -r FOLDER URL DB_NAME DB_USER DB_PASS SITE_TITLE ADMIN_USER ADMIN_EMAIL <<< "$SITE"
echo "=== Setting up $URL in $REMOTE_BASE/$FOLDER ==="
ssh -p "$SSH_PORT" "$USER@$HOST" bash << EOSSH
set -e
cd "$REMOTE_BASE"
# Create folder if not exist
mkdir -p "$FOLDER"
cd "$FOLDER"
# Download WordPress if not already
if [ ! -f "wp-load.php" ]; then
  echo "Downloading WordPress for $URL ..."
  wget https://wordpress.org/latest.tar.gz -O wp.tar.gz
  tar -xzf wp.tar.gz --strip-components=1
  rm wp.tar.gz
fi
# Create wp-config.php if not exists
if [ ! -f "wp-config.php" ]; then
  cp wp-config-sample.php wp-config.php
  sed -i "s/database_name_here/$DB_NAME/" wp-config.php
  sed -i "s/username_here/$DB_USER/" wp-config.php
  sed -i "s/password_here/$DB_PASS/" wp-config.php
  sed -i "s/localhost/$DB_HOST/" wp-config.php
fi
# Create DB and user if possible
mysql -u"$DB_ROOT_USER" -p"$DB_ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS \\\`$DB_NAME\\\`;"
mysql -u"$DB_ROOT_USER" -p"$DB_ROOT_PASS" -e "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';"
mysql -u"$DB_ROOT_USER" -p"$DB_ROOT_PASS" -e "GRANT ALL PRIVILEGES ON \\\`$DB_NAME\\\`.* TO '$DB_USER'@'%'; FLUSH PRIVILEGES;"
# If wp core is not installed, run install via WP-CLI if available
if command -v wp >/dev/null 2>&1; then
  if ! wp core is-installed --path="$(pwd)" >/dev/null 2>&1; then
    echo "Running wp core install for $URL ..."
    wp core install \
      --url="$URL" \
      --title="$SITE_TITLE" \
      --admin_user="$ADMIN_USER" \
      --admin_password="ChangeMe123!" \
      --admin_email="$ADMIN_EMAIL" \
      --skip-email
  else
    echo "WordPress already installed for $URL"
  fi
else
  echo "WP-CLI not found. Please install WP-CLI for full automation, or finish installation via browser."
fi
EOSSH
done
echo "All site setup commands executed."
