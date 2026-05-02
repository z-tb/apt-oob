#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# 3-component version
result=$(expand_template "1.21.6" "https://example.com/go%VERSION%.linux-amd64.tar.gz")
assert_eq "https://example.com/go1.21.6.linux-amd64.tar.gz" "$result" "3-component VERSION"

result=$(expand_template "1.21.6" "https://example.com/%MAJOR%/%MINOR%/%REVISION%")
assert_eq "https://example.com/1/21/6" "$result" "3-component MAJOR/MINOR/REVISION"

# 2-component version - REVISION should be empty
result=$(expand_template "148.0" "https://example.com/%VERSION%/%REVISION%/file.tar.xz")
assert_eq "https://example.com/148.0//file.tar.xz" "$result" "2-component empty REVISION"

result=$(expand_template "148.0" "https://example.com/%MAJOR%.%MINOR%")
assert_eq "https://example.com/148.0" "$result" "2-component MAJOR.MINOR"

# No substitution needed
result=$(expand_template "1.0.0" "https://example.com/static.tar.gz")
assert_eq "https://example.com/static.tar.gz" "$result" "no placeholders"

teardown
report "expand_template"
