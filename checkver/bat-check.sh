#!/bin/bash
TAG=$(curl -sf "https://api.github.com/repos/sharkdp/bat/releases/latest" \
  | grep -oP '"tag_name"\s*:\s*"\Kv[^"]+')
[ -z "$TAG" ] && exit 1
echo "${TAG#v}"
