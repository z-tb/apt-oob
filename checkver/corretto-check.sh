#!/bin/bash
# Called by oob. Print latest version string to stdout and exit 0.
# Get latest Corretto 26 version from GitHub (e.g. "26.0.1.8.1")

TAG=$(curl -sf "https://api.github.com/repos/corretto/corretto-26/releases/latest" \
  | jq -r '.tag_name')

[ -z "$TAG" ] && exit 1
echo "$TAG"
