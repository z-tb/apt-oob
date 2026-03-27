#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Up to date
create_test_conf "uptodate"
create_test_checkver "uptodate" "1.0.0"
mkdir -p "${OOB_LIVE}/uptodate"
write_state "uptodate" "1.0.0" "${OOB_LIVE}/uptodate" ""

# Update available
create_test_conf "outdated"
create_test_checkver "outdated" "2.0.0"
mkdir -p "${OOB_LIVE}/outdated"
write_state "outdated" "1.0.0" "${OOB_LIVE}/outdated" ""

# Not installed
create_test_conf "fresh"
create_test_checkver "fresh" "1.0.0"

TARGET_NAME=""
FLAG_QUIET=0
output=$(cmd_check 2>&1)
FLAG_QUIET=1
assert_contains "$output" "up to date" "up to date detected"
assert_contains "$output" "outdated" "outdated detected"
assert_contains "$output" "not installed" "not installed detected"

# Single package check
TARGET_NAME="outdated"
FLAG_QUIET=0
output=$(cmd_check 2>&1)
FLAG_QUIET=1
assert_contains "$output" "installed=1.0.0" "single check shows installed"
assert_contains "$output" "available=2.0.0" "single check shows available"

teardown
report "check"
