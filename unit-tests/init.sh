#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# init creates directories and hook
cmd_init
assert_ok $? "init succeeds"
assert_file_exists "$APT_HOOK" "hook file created"
assert_dir_exists "$OOB_CONF" "conf.d created"
assert_dir_exists "$OOB_LIVE" "live created"
assert_dir_exists "$OOB_STATE" "state created"
assert_dir_exists "$OOB_CHECKVER" "checkver created"
assert_dir_exists "$OOB_DLOAD" "dload created"
assert_dir_exists "$OOB_CHECKSUM" "checksum created"
assert_dir_exists "$OOB_CHECKSIG" "checksig created"
assert_dir_exists "$OOB_KEYS" "keys created"

# Hook content
hook_content=$(cat "$APT_HOOK")
assert_contains "$hook_content" "oob install -q" "hook runs oob install"

# init again warns (force to skip prompt)
FLAG_FORCE=1
cmd_init
assert_ok $? "init with force overwrites"

teardown
report "init"
