#!/bin/bash
# Called by oob. Print latest version string to stdout and exit 0.
# Get latest Thunderbird version from Mozilla (e.g. "138.0")

VERSION=$(curl -sf 'https://product-details.mozilla.org/1.0/thunderbird_versions.json' \
  | jq -r '.LATEST_THUNDERBIRD_VERSION')

[ -z "$VERSION" ] && exit 1
echo "$VERSION"
