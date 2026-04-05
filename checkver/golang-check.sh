#!/bin/bash
# Go publishes the current version at this endpoint
VER=$(curl -sf 'https://go.dev/VERSION?m=text' | head -1)
[ -z "$VER" ] && exit 1
# Strip "go" prefix: go1.26.1 -> 1.26.1
echo "${VER#go}"
