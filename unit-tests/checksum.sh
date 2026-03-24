#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

NAME="testpkg"

# Create a test file
echo "test content" > "${TEST_TMPDIR}/archive.tar.gz"
EXPECTED_SHA256=$(sha256sum "${TEST_TMPDIR}/archive.tar.gz" | awk '{print $1}')

# sha256 match
cat > "${OOB_CHECKSUM}/good-sha256.sh" <<EOF
#!/bin/bash
echo "sha256:${EXPECTED_SHA256}"
EOF
chmod +x "${OOB_CHECKSUM}/good-sha256.sh"
CHECKSUM="good-sha256.sh"
run_checksum "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_ok $? "sha256 match"

# sha256 mismatch
cat > "${OOB_CHECKSUM}/bad-sha256.sh" <<'EOF'
#!/bin/bash
echo "sha256:0000000000000000000000000000000000000000000000000000000000000000"
EOF
chmod +x "${OOB_CHECKSUM}/bad-sha256.sh"
CHECKSUM="bad-sha256.sh"
run_checksum "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_fail $? "sha256 mismatch"

# sha512 match
EXPECTED_SHA512=$(sha512sum "${TEST_TMPDIR}/archive.tar.gz" | awk '{print $1}')
cat > "${OOB_CHECKSUM}/good-sha512.sh" <<EOF
#!/bin/bash
echo "sha512:${EXPECTED_SHA512}"
EOF
chmod +x "${OOB_CHECKSUM}/good-sha512.sh"
CHECKSUM="good-sha512.sh"
run_checksum "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_ok $? "sha512 match"

# bad algorithm
cat > "${OOB_CHECKSUM}/bad-algo.sh" <<'EOF'
#!/bin/bash
echo "md5:abc123"
EOF
chmod +x "${OOB_CHECKSUM}/bad-algo.sh"
CHECKSUM="bad-algo.sh"
run_checksum "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_fail $? "unsupported algo"

# script not found
CHECKSUM="nonexistent.sh"
run_checksum "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_fail $? "script not found"

# none skips
CHECKSUM="none"
run_checksum "1.0.0" "${TEST_TMPDIR}/archive.tar.gz" 2>/dev/null
assert_ok $? "none skips"

teardown
report "checksum"
