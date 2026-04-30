#!/bin/bash
# Get latest Nextcloud Talk desktop version from GitHub (e.g. "1.0.2")

TAG=$(curl -sf "https://api.github.com/repos/nextcloud-releases/talk-desktop/releases/latest" \
  | jq -r '.tag_name')

[ -z "$TAG" ] && exit 1
echo "${TAG#v}"
