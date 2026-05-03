#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Every command in the dispatch must be accepted by parse_args.
# This catches the case where a cmd_* function exists but parse_args
# doesn't recognize the command name.

for cmd in update upgrade install remove list status enable disable init deinit; do
    COMMAND=""
    TARGET_NAME=""
    parse_args "$cmd" 2>/dev/null
    assert_eq "$cmd" "$COMMAND" "parse_args accepts '$cmd'"
done

# Commands that take a name argument
for cmd in install remove status enable disable; do
    COMMAND=""
    TARGET_NAME=""
    parse_args "$cmd" "mypkg" 2>/dev/null
    assert_eq "mypkg" "$TARGET_NAME" "'$cmd' accepts package name"
done

# Unknown command should fail
COMMAND=""
(parse_args "bogus" 2>/dev/null)
assert_fail $? "rejects unknown command"

# install without a name should error
COMMAND=""
TARGET_NAME=""
parse_args "install" 2>/dev/null
output=$(cmd_install 2>&1)
assert_fail $? "install without name fails"

teardown
report "parse-args"
