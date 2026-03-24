#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

NAME="testpkg"
echo "test" > "${TEST_TMPDIR}/archive.tar.gz"

# pass
cat > "${OOB_CHECKSIG}/pass.sh" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "${OOB_CHECKSIG}/pass.sh"
CHECKSIG="pass.sh"
run_checksig "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_ok $? "checksig pass"

# fail
cat > "${OOB_CHECKSIG}/fail.sh" <<'EOF'
#!/bin/bash
exit 1
EOF
chmod +x "${OOB_CHECKSIG}/fail.sh"
CHECKSIG="fail.sh"
run_checksig "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_fail $? "checksig fail"

# script not found
CHECKSIG="nonexistent.sh"
run_checksig "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_fail $? "script not found"

# none skips
CHECKSIG="none"
run_checksig "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_ok $? "none skips"

teardown
report "checksig"
