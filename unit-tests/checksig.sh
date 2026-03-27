#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

NAME="testpkg"
echo "test" > "${TEST_TMPDIR}/archive.tar.gz"

# No GPG_KEY — skip silently
GPG_KEY=""
run_gpg_verify "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_ok $? "empty GPG_KEY skips"

# GPG_KEY set but key file missing
GPG_KEY="missing.gpg"
GPG_SIG_URL="https://example.com/sig.asc"
run_gpg_verify "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_fail $? "missing key file fails"

# GPG_KEY set but no GPG_SIG_URL
GPG_KEY="test.gpg"
touch "${OOB_KEYS}/test.gpg"
unset GPG_SIG_URL
run_gpg_verify "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_fail $? "missing GPG_SIG_URL fails"

teardown
report "checksig"
