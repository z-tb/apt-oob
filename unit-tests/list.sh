#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Installed package
create_test_conf "pkga"
write_state "pkga" "2.0.0" "${OOB_LIVE}/pkga" "pkga:${TEST_TMPDIR}/bin/pkga"

# Configured but not installed
create_test_conf "pkgb"

FLAG_QUIET=0
output=$(cmd_list 2>&1)
FLAG_QUIET=1
assert_contains "$output" "pkga: 2.0.0" "installed shows version"
assert_contains "$output" "pkgb: configured, not installed" "uninstalled shows status"

teardown
report "list"
