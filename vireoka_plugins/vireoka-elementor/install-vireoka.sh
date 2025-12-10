#!/bin/bash

echo "Downloading latest WordPress..."
wget https://wordpress.org/latest.zip
unzip latest.zip
mv wordpress vireoka.com

cd vireoka.com

echo "Creating wp-config..."
cp wp-config-sample.php wp-config.php
sed -i '' "s/database_name_here/vireoka_db/" wp-config.php
sed -i '' "s/username_here/root/" wp-config.php
sed -i '' "s/password_here/root/" wp-config.php

echo "Installing recommended plugins..."
wp plugin install elementor --activate
wp plugin install astra --activate
wp plugin install fluentform --activate
wp plugin install rank-math --activate

echo "Setting Astra theme as default..."
wp theme activate astra

echo "Importing Elementor templates..."
wp elementor templates import ../vireoka-elementor/*.json

echo "Done — Vireoka WordPress site installed."
