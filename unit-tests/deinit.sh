#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# deinit when hook exists
echo "hook content" > "$APT_HOOK"
cmd_deinit
assert_ok $? "deinit succeeds"
assert_file_not_exists "$APT_HOOK" "hook file removed"

# deinit when hook missing
cmd_deinit 2>/dev/null
assert_ok $? "deinit with no hook is ok"

teardown
report "deinit"
