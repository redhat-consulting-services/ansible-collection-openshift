#!/bin/sh
set -eu

script_dir="$(CDPATH='' cd "$(dirname "$0")" && pwd)"
# save the real curl for HEAD checks
real_curl="$(command -v curl)"
test_dir="$(mktemp -d)"
mkdir "$test_dir/bin"

# remove test files
cleanup() {
    rm -f "$test_dir/bin/uname" "$test_dir/bin/curl" "$test_dir/bin/tar" \
        "$test_dir/bin/chmod" "$test_dir/bin/openshift-install" "$test_dir/urls" \
        "$test_dir/versions" "$test_dir/matrix-urls"
    rmdir "$test_dir/bin" "$test_dir"
}
trap cleanup EXIT

# mock external commands without installing binaries
cat > "$test_dir/bin/uname" <<'EOF'
#!/bin/sh
echo "$TEST_HOST"
EOF
cat > "$test_dir/bin/curl" <<'EOF'
#!/bin/sh
[ "${TEST_FAIL_DOWNLOAD:-0}" != 1 ] || exit 22
printf '%s\n' "$4" >> "$TEST_URLS"
EOF
cat > "$test_dir/bin/tar" <<'EOF'
#!/bin/sh
exit 0
EOF
cat > "$test_dir/bin/chmod" <<'EOF'
#!/bin/sh
exit 0
EOF
cat > "$test_dir/bin/openshift-install" <<'EOF'
#!/bin/sh
echo "release architecture $TEST_RELEASE_ARCH"
EOF
/bin/chmod +x "$test_dir/bin/uname" "$test_dir/bin/curl" "$test_dir/bin/tar" \
    "$test_dir/bin/chmod" "$test_dir/bin/openshift-install"

export PATH="$test_dir/bin:$PATH" TEST_URLS="$test_dir/urls"
script="$script_dir/install-openshift-tools.sh"
mirror=https://mirror.openshift.com/pub/openshift-v4

# require a nonempty matrix of version strings
jq -er '
    .openshift_versions |
    if type != "array" or length == 0 then
        error("openshift_versions must be a non-empty array")
    elif any(.[]; type != "string" or length == 0 or contains("\n")) then
        error("openshift_versions must contain non-empty version strings")
    else
        .[]
    end
' "$script_dir/../.github/openshift-versions.json" > "$test_dir/versions"

# clear the matrix URLs file
# shellcheck disable=SC2188
> "$test_dir/matrix-urls"

# check the URLs selected for an EE host and payload against the expected installer
check_tool_urls() {
    TEST_HOST=$1
    OPENSHIFT_PAYLOAD_ARCH=$2
    installer_url=$3
    case "$TEST_HOST" in
        x86_64) host=amd64; host_mirror="$amd64_mirror" ;;
        aarch64) host=arm64; host_mirror="$arm64_mirror" ;;
    esac
    # the native installer reports the host architecture
    TEST_RELEASE_ARCH="$OPENSHIFT_PAYLOAD_ARCH"
    [ "$TEST_RELEASE_ARCH" != native ] || TEST_RELEASE_ARCH="$host"
    export TEST_HOST OPENSHIFT_PAYLOAD_ARCH TEST_RELEASE_ARCH
    # OpenShift 5.x uses an unversioned oc-mirror for the EE host
    case "$OPENSHIFT_VERSION" in
        5.*) mirror_url="https://mirror.openshift.com/pub/cgw/oc-mirror/latest/oc-mirror-rhel9-linux-$host.tar.gz" ;;
        *) mirror_url="$host_mirror/oc-mirror.tar.gz" ;;
    esac
    # capture the URLs without installing anything
    : > "$TEST_URLS"
    sh "$script"
    [ "$(wc -l < "$TEST_URLS" | tr -d ' ')" = 3 ]
    grep -Fx "$installer_url" "$TEST_URLS" > /dev/null
    grep -Fx "$host_mirror/openshift-client-linux.tar.gz" "$TEST_URLS" > /dev/null
    grep -Fx "$mirror_url" "$TEST_URLS" > /dev/null
    cat "$TEST_URLS" >> "$test_dir/matrix-urls"
}

# test each version, host, and payload with the mocks
while IFS= read -r OPENSHIFT_VERSION; do
    export OPENSHIFT_VERSION
    echo "Collecting tool URLs for OpenShift $OPENSHIFT_VERSION"
    amd64_mirror="$mirror/clients/ocp/$OPENSHIFT_VERSION"
    arm64_mirror="$mirror/aarch64/clients/ocp/$OPENSHIFT_VERSION"
    multi_mirror="$mirror/multi/clients/ocp/$OPENSHIFT_VERSION"

    # arguments: EE host, payload, expected installer URL
    check_tool_urls x86_64 amd64 "$amd64_mirror/openshift-install-linux.tar.gz"
    check_tool_urls x86_64 arm64 "$arm64_mirror/openshift-install-linux-amd64.tar.gz"
    check_tool_urls x86_64 multi "$multi_mirror/amd64/openshift-install-linux.tar.gz"
    check_tool_urls x86_64 native "$amd64_mirror/openshift-install-linux.tar.gz"

    check_tool_urls aarch64 amd64 "$amd64_mirror/openshift-install-linux-arm64.tar.gz"
    check_tool_urls aarch64 arm64 "$arm64_mirror/openshift-install-linux.tar.gz"
    check_tool_urls aarch64 multi "$multi_mirror/arm64/openshift-install-linux.tar.gz"
    check_tool_urls aarch64 native "$arm64_mirror/openshift-install-linux.tar.gz"
done < "$test_dir/versions"

# use a valid host and version when testing failures
TEST_HOST=x86_64
OPENSHIFT_VERSION="$(head -n 1 "$test_dir/versions")"
export TEST_HOST OPENSHIFT_VERSION

# reject invalid payloads, mismatches, and download failures
expect_failure() {
    expected_status=$1
    expected_message=$2
    shift 2
    status=0
    output=$(env "$@" sh "$script" 2>&1) || status=$?
    if [ "$status" -ne "$expected_status" ] ||
        { [ -n "$expected_message" ] && ! printf '%s\n' "$output" | grep -F "$expected_message" > /dev/null; }; then
        echo "Unexpected failure (status $status): $output" >&2
        exit 1
    fi
}
expect_failure 1 "Unsupported OpenShift installer payload" OPENSHIFT_PAYLOAD_ARCH=invalid
expect_failure 1 "Expected installer payload amd64, got arm64" OPENSHIFT_PAYLOAD_ARCH=amd64 TEST_RELEASE_ARCH=arm64
expect_failure 22 "" OPENSHIFT_PAYLOAD_ARCH=amd64 TEST_RELEASE_ARCH=amd64 TEST_FAIL_DOWNLOAD=1

# check each shared URL once without downloading archives
sort -u -o "$test_dir/matrix-urls" "$test_dir/matrix-urls"
echo "Checking $(wc -l < "$test_dir/matrix-urls" | tr -d ' ') unique tool URLs"
# shellcheck disable=SC2016
xargs -n 1 -P 8 sh -c '
    status=$("$1" --head --fail --silent --show-error --location --retry 2 \
        --connect-timeout 10 --max-time 60 --output /dev/null --write-out "%{http_code}" "$2") || {
        echo "Failed to verify URL: $2" >&2
        exit 1
    }
    case "$status" in
        2??) ;;
        *) echo "Unexpected HTTP status $status: $2" >&2; exit 1 ;;
    esac
' _ "$real_curl" < "$test_dir/matrix-urls"
echo "OpenShift tool selection tests passed."
