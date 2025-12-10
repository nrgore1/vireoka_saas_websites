#!/bin/bash

source ./vireoka-sync.conf

echo "============================================="
echo " 🧠 Git-Aware Deploy"
echo "============================================="

git add .
git commit -m "Auto deploy $(date)"
git push

./vsync-deploy.sh