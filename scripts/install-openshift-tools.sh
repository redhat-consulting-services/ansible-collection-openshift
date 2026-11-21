#!/bin/sh
set -eu

# select client binaries for the EE host architecture
case "$(uname -m)" in
    x86_64) host_arch=amd64 ;;
    aarch64|arm64) host_arch=arm64 ;;
    *) echo "Unsupported EE architecture: $(uname -m)" >&2; exit 1 ;;
esac

# select the installer payload independently of the EE architecture
case "${OPENSHIFT_PAYLOAD_ARCH:-native}" in
    native) payload_arch="$host_arch" ;;
    amd64|arm64|multi) payload_arch="$OPENSHIFT_PAYLOAD_ARCH" ;;
    *) echo "Unsupported OpenShift installer payload: $OPENSHIFT_PAYLOAD_ARCH" >&2; exit 1 ;;
esac

# use host-specific client archives
mirror=https://mirror.openshift.com/pub/openshift-v4
case "$host_arch" in
    amd64) host_mirror="$mirror/clients/ocp/$OPENSHIFT_VERSION" ;;
    arm64) host_mirror="$mirror/aarch64/clients/ocp/$OPENSHIFT_VERSION" ;;
esac

# multi-payload archives are grouped by installer host architecture
case "$payload_arch" in
    amd64) installer_mirror="$mirror/clients/ocp/$OPENSHIFT_VERSION" ;;
    arm64) installer_mirror="$mirror/aarch64/clients/ocp/$OPENSHIFT_VERSION" ;;
    multi) installer_mirror="$mirror/multi/clients/ocp/$OPENSHIFT_VERSION/$host_arch" ;;
esac

# use a host-specific installer archive for cross-architecture payloads
installer_archive=openshift-install-linux.tar.gz
if [ "$payload_arch" != multi ] && [ "$payload_arch" != "$host_arch" ]; then
    installer_archive="openshift-install-linux-$host_arch.tar.gz"
fi

# use the latest RHEL 9 oc-mirror archive for OpenShift 5.x
case "$OPENSHIFT_VERSION" in
    5.*) mirror_url="https://mirror.openshift.com/pub/cgw/oc-mirror/latest/oc-mirror-rhel9-linux-$host_arch.tar.gz" ;;
    *) mirror_url="$host_mirror/oc-mirror.tar.gz" ;;
esac

# remove downloaded archives even if installation fails
tmp_dir="$(mktemp -d)"
trap 'rm -f "$tmp_dir/install.tar.gz" "$tmp_dir/client.tar.gz" "$tmp_dir/mirror.tar.gz"; rmdir "$tmp_dir"' EXIT

# install CLI tools (openshift-install, oc, kubectl and oc-mirror)
curl -fL -o "$tmp_dir/install.tar.gz" "$installer_mirror/$installer_archive"
tar -xzf "$tmp_dir/install.tar.gz" -C /usr/local/bin openshift-install
curl -fL -o "$tmp_dir/client.tar.gz" "$host_mirror/openshift-client-linux.tar.gz"
tar -xzf "$tmp_dir/client.tar.gz" -C /usr/local/bin oc kubectl
curl -fL -o "$tmp_dir/mirror.tar.gz" "$mirror_url"
tar -xzf "$tmp_dir/mirror.tar.gz" -C /usr/local/bin oc-mirror
chmod +x /usr/local/bin/openshift-install /usr/local/bin/oc /usr/local/bin/kubectl /usr/local/bin/oc-mirror

# verify the installer contains the requested release payload
actual_arch="$(openshift-install version | awk '$1 == "release" && $2 == "architecture" {print $3}')"
if [ "$actual_arch" != "$payload_arch" ]; then
    echo "Expected installer payload $payload_arch, got ${actual_arch:-unknown}" >&2
    exit 1
fi
