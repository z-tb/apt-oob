#!/bin/bash
# Get latest Firefox version from Mozilla (e.g. "138.0")

VERSION=$(curl -sf 'https://product-details.mozilla.org/1.0/firefox_versions.json' \
  | jq -r '.LATEST_FIREFOX_VERSION')

[ -z "$VERSION" ] && exit 1
echo "$VERSION"
