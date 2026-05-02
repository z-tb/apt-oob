#!/bin/bash
# Called by oob. Print latest version string to stdout and exit 0.
# Get latest bat version from GitHub (e.g. "0.25.0")

TAG=$(curl -sf "https://api.github.com/repos/sharkdp/bat/releases/latest" \
  | jq -r '.tag_name')

[ -z "$TAG" ] && exit 1
echo "${TAG#v}"
