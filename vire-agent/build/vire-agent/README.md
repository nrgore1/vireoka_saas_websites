# Vire Agent Platform

Generate and deploy AI-powered websites.

## Generate
./cli/vire templates/sites/atmasphere.json

## Export
python3 export/wp_static_export.py

## Build
cd build && ./build.sh

## Deploy
WP_CONTAINER=vireoka_wp ./deploy/deploy_wp.sh
