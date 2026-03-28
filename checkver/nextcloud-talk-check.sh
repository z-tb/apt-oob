#!/bin/bash
# Get latest Nextcloud Talk desktop version from GitHub API
TAG=$(curl -sf "https://api.github.com/repos/nextcloud-releases/talk-desktop/releases/latest" \
  | grep -oP '"tag_name"\s*:\s*"\Kv[^"]+')
[ -z "$TAG" ] && exit 1
# Strip leading 'v'
echo "${TAG#v}"
