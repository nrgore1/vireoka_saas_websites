#!/bin/bash

while true; do
  bash "$(dirname "$0")/vsync.sh" plugins silent
  bash "$(dirname "$0")/vsync.sh" themes silent
  bash "$(dirname "$0")/vsync.sh" uploads silent
  sleep 10
done
