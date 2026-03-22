# apt-oob

**apt-oob** is a lightweight out-of-band software manager for Debian-based systems. It manages software that has no apt repository — packages distributed as tarballs with a download URL — handling version checking, verification, installation, and symlinking.

apt-oob integrates with the standard apt upgrade process and runs automatically when `apt upgrade` or `apt-get upgrade` is invoked.

---

## APT Integration

apt-oob registers itself as an apt post-invoke hook by dropping a configuration file into `/etc/apt/apt.conf.d/`:

```
# /etc/apt/apt.conf.d/99apt-oob
DPkg::Post-Invoke {"if [ -x /usr/local/apt-oob/bin/oob ]; then /usr/local/apt-oob/bin/oob upgrade; fi";};
```

`DPkg::Post-Invoke` runs after dpkg has completed all of its own operations, so apt-oob runs in the same terminal session after apt finishes. The user sees apt-oob output as a natural continuation of the upgrade process. If `oob upgrade` exits non-zero, apt may report a post-invoke failure even though the apt upgrade itself succeeded — `oob` should therefore be careful to only exit non-zero on genuine errors.

---

## Directory Structure

```
/usr/local/apt-oob/
├── bin/
│   └── oob                  # Main executable
├── conf.d/                  # Package configuration files (sourced in lexical order)
│   ├── 10-golang
│   └── 20-minecraft
├── vcheck/                  # Version check scripts (print latest version string to stdout)
│   ├── golang-check.sh
│   └── minecraft-check.sh
├── dload/                   # Download URL resolution scripts (receive version as $1, print URL to stdout)
│   ├── golang-download.sh
│   └── minecraft-download.sh
├── keys/                    # ASCII-armored GPG public keys for package verification (.asc files)
│   └── golang-signing.asc
├── live/                    # Extracted package installations
│   └── golang/
│       └── go/              # Extracted as-is from tarball, no renaming
└── state/                   # Installed package state (one file per package)
    └── golang
```

**Logging** is written to `/var/log/apt-oob.log`.

---

## conf.d File Format

Configuration files are plain shell-sourceable key=value files. They are loaded in lexical order — numeric prefixes (`10-`, `20-`) control precedence. Each file configures one package.

### Template Variables

The following variables are available for use in `DOWNLOAD`, `VERIFY_CHECKSUM_URL`, and `VERIFY_GPG_SIG_URL` when those fields contain an `https://` URL. They are substituted by `oob` at runtime using the version string returned by `VERSION_CHECK`.

| Variable | Description |
|---|---|
| `{VERSION}` | Full version string e.g. `1.21.6` |
| `{MAJOR}` | Major component e.g. `1` |
| `{MINOR}` | Minor component e.g. `21` |
| `{REVISION}` | Revision component e.g. `6` |

---

### Reference

```sh
# conf.d/10-golang

# Package name — used for directory naming under live/ and state/
NAME="golang"

# Download source. Either:
#   https:// URL — supports {VERSION} {MAJOR} {MINOR} {REVISION} template variables
#   script name  — resolved under apt-oob/dload/, receives latest version as $1, prints URL to stdout
DOWNLOAD="golang-download.sh"
# or: DOWNLOAD="https://go.dev/dl/go{VERSION}.linux-amd64.tar.gz"

# Verification method: checksum_url | gpg | script | none
VERIFY_METHOD="checksum_url"

# URL to fetch checksum file from (used when VERIFY_METHOD=checksum_url)
# Supports {VERSION} {MAJOR} {MINOR} {REVISION} template variables
VERIFY_CHECKSUM_URL="https://go.dev/dl/go{VERSION}.linux-amd64.tar.gz.sha256"

# ASCII-armored public key filename under apt-oob/keys/ (used when VERIFY_METHOD=gpg)
# Key is imported into a temporary isolated keyring at verify time — the system keyring is never touched
#VERIFY_GPG_KEY="golang-signing.asc"

# URL to fetch the detached signature file from (used when VERIFY_METHOD=gpg)
# Supports {VERSION} {MAJOR} {MINOR} {REVISION} template variables
#VERIFY_GPG_SIG_URL="https://go.dev/dl/go{VERSION}.linux-amd64.tar.gz.asc"

# Verification script under apt-oob/vcheck/ (used when VERIFY_METHOD=script)
# Receives path to downloaded archive as $1. Must exit 0 on success, 1 on failure
#VERIFY_SCRIPT="golang-verify.sh"

# Version check script under apt-oob/vcheck/
# Must print the latest available version string to stdout and exit 0 on success
VERSION_CHECK="golang-check.sh"

# Base directory to extract the package archive into
# The tarball is extracted as-is — no renaming or stripping of top-level directories
# Actual install path is recorded in state after extraction
INSTALL_DIR="${OOB_LIVE}/${NAME}"

# Space-separated list of symlinks to create
# Format: "linkname:path_relative_to_INSTALL_DIR"
# Path must include the top-level directory the tarball extracts to
SYMLINKS="go:go/bin/go gofmt:go/bin/gofmt"

# Directory in which symlinks are created
SYMLINK_DIR="/usr/local/bin"
```

---

## State Files

Each installed package has a corresponding state file under `state/`. These are written atomically on install and updated on upgrade. The state directory acts as the installed package index — `ls state/` lists all managed packages.

```sh
# state/golang
INSTALLED_VERSION="1.21.6"
INSTALL_DATE="2026-03-22T10:23:00Z"
INSTALL_PATH="/usr/local/apt-oob/live/golang/go"
CHECKSUM_SHA256="abc123def456..."
SYMLINKS="go:/usr/local/bin/go gofmt:/usr/local/bin/gofmt"
```

---

## vcheck/ Scripts

Scripts placed under `vcheck/` are responsible for discovering the latest available version of a package. They must:

- Print a single version string to stdout (e.g. `1.22.0`)
- Exit `0` on success
- Exit non-zero if the version cannot be determined

---

## dload/ Scripts

Scripts placed under `dload/` are responsible for resolving the download URL for a given version. They must:

- Accept the version string as `$1`
- Print a single `https://` URL to stdout
- Exit `0` on success
- Exit non-zero on failure

---

## keys/

ASCII-armored GPG public key files (`.asc`) used for verification when `VERIFY_METHOD=gpg`. Referenced by filename in `VERIFY_GPG_KEY`. At verification time `oob` imports the key into a temporary isolated keyring and verifies the detached signature against the downloaded archive. The system GPG keyring is never read from or written to.