#!/bin/bash
rsync -avz \
  --delete \
  --exclude='uploads/' \
  --exclude='cache/' \
  --exclude='litespeed/' \
  --exclude='wp-config.php' \
  --exclude='.htaccess' \
  u814009065@45.137.159.84:/home/u814009065/domains/vireoka.com/public_html/wp-content/themes/vireoka-core/ \
  /mnt/c/Projects2025/vireoka_website/verioka_local/vireoka-core/
