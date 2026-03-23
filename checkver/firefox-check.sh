#!/bin/bash
curl -sf 'https://product-details.mozilla.org/1.0/firefox_versions.json' \
  | grep -oP '"LATEST_FIREFOX_VERSION"\s*:\s*"\K[^"]+'
