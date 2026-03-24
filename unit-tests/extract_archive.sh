#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

DEST="${TEST_TMPDIR}/extract"
NAME="testpkg"

# tar.gz
mkdir -p "${TEST_TMPDIR}/src"
echo "hello" > "${TEST_TMPDIR}/src/file.txt"
tar czf "${TEST_TMPDIR}/test.tar.gz" -C "${TEST_TMPDIR}" src
extract_archive "${TEST_TMPDIR}/test.tar.gz" "$DEST/tgz"
assert_file_exists "$DEST/tgz/src/file.txt" "tar.gz extracted"

# tar.xz
tar cJf "${TEST_TMPDIR}/test.tar.xz" -C "${TEST_TMPDIR}" src
extract_archive "${TEST_TMPDIR}/test.tar.xz" "$DEST/txz"
assert_file_exists "$DEST/txz/src/file.txt" "tar.xz extracted"

# tar.bz2
tar cjf "${TEST_TMPDIR}/test.tar.bz2" -C "${TEST_TMPDIR}" src
extract_archive "${TEST_TMPDIR}/test.tar.bz2" "$DEST/tbz2"
assert_file_exists "$DEST/tbz2/src/file.txt" "tar.bz2 extracted"

# zip (skip if zip not installed)
if command -v zip &>/dev/null; then
    (cd "${TEST_TMPDIR}" && zip -qr test.zip src)
    extract_archive "${TEST_TMPDIR}/test.zip" "$DEST/zip"
    assert_file_exists "$DEST/zip/src/file.txt" "zip extracted"
fi

# unsupported
extract_archive "${TEST_TMPDIR}/test.rar" "$DEST/rar" 2>/dev/null
assert_fail $? "unsupported format fails"

teardown
report "extract_archive"
