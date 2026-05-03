#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Create two packages with local tarballs
for pkg in alpha bravo; do
    mkdir -p "${TEST_TMPDIR}/src/${pkg}/bin"
    echo "bin" > "${TEST_TMPDIR}/src/${pkg}/bin/${pkg}"
    tar czf "${TEST_TMPDIR}/${pkg}-1.0.0.tar.gz" -C "${TEST_TMPDIR}/src" "$pkg"

    cat > "${OOB_DLOAD}/${pkg}-download.sh" <<EOF
#!/bin/bash
echo "file://${TEST_TMPDIR}/${pkg}-1.0.0.tar.gz"
EOF
    chmod +x "${OOB_DLOAD}/${pkg}-download.sh"

    cat > "${OOB_CONF}/10-${pkg}" <<EOF
NAME="${pkg}"
DOWNLOAD="${pkg}-download.sh"
CHECKSUM="none"
VERSION_CHECK="${pkg}-check.sh"
INSTALL_DIR="${OOB_LIVE}/${pkg}"
SYMLINKS="${pkg}:${pkg}/bin/${pkg}"
SYMLINK_DIR="${TEST_TMPDIR}/bin"
EOF
    mkdir -p "${TEST_TMPDIR}/bin"
    create_test_checkver "$pkg" "1.0.0"
done

# Disable bravo
mv "${OOB_CONF}/10-bravo" "${OOB_CONF}/10-bravo.disabled"

# Upgrade should install alpha but skip bravo
TARGET_NAME=""
cmd_upgrade 2>&1
assert_ok $? "upgrade succeeds"
assert_file_exists "${OOB_STATE}/alpha" "alpha installed"
assert_file_not_exists "${OOB_STATE}/bravo" "bravo skipped (disabled)"

teardown
report "upgrade"
