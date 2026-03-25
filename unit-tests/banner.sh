#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# fancy banner
FLAG_QUIET=0
BANNER="fancy"
output=$(show_banner 2>&1)
assert_contains "$output" "apt-oob" "fancy contains apt-oob"
assert_contains "$output" "$OOB_VERSION" "fancy contains version"
assert_contains "$output" "░" "fancy contains shading"

# simple banner
BANNER="simple"
output=$(show_banner 2>&1)
assert_contains "$output" "apt-oob - v${OOB_VERSION}" "simple format"

# none banner
BANNER="none"
output=$(show_banner 2>&1)
assert_eq "" "$output" "none produces no output"

# quiet suppresses all banners
FLAG_QUIET=1
BANNER="fancy"
output=$(show_banner 2>&1)
assert_eq "" "$output" "quiet suppresses fancy"

teardown
report "banner"
