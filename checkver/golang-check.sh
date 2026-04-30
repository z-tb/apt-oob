#!/bin/bash
# Get latest Go version (e.g. "1.26.1")

VER=$(curl -sf 'https://go.dev/VERSION?m=text' | head -1)

[ -z "$VER" ] && exit 1
echo "${VER#go}"
