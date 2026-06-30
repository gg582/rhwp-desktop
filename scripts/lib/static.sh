#!/usr/bin/env bash
# Shared helpers for static/distro packaging scripts.
# Do not run directly; source from another script.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ ! -f "${ROOT_DIR}/desktop/package.json" ]]; then
  echo "desktop/package.json not found (wrong working directory?)" >&2
  exit 1
fi

VERSION="$(node -p "require('${ROOT_DIR}/desktop/package.json').version")"

# Host architecture detection. Override with ARCH=<arch> if desired.
HOST_ARCH="$(uname -m)"
case "${HOST_ARCH}" in
  x86_64)
    HOST_ARCH="x64"
    ;;
  aarch64|arm64)
    HOST_ARCH="arm64"
    ;;
esac
ARCH="${ARCH:-${HOST_ARCH}}"

case "${ARCH}" in
  x64)
    DEB_ARCH="amd64"
    RPM_ARCH="x86_64"
    ;;
  arm64)
    DEB_ARCH="arm64"
    RPM_ARCH="aarch64"
    ;;
  *)
    echo "Unsupported architecture: ${ARCH}" >&2
    echo "Supported: x64, arm64" >&2
    exit 1
    ;;
esac

STATIC_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist-static}"
BUNDLE_NAME="rhwp-desktop-${VERSION}-linux-${ARCH}"
BUNDLE_DIR="${STATIC_DIR}/${BUNDLE_NAME}"
TARBALL="${STATIC_DIR}/${BUNDLE_NAME}.tar.gz"

require_static_bundle() {
  if [[ ! -d "${BUNDLE_DIR}" ]]; then
    echo "Static bundle not found: ${BUNDLE_DIR}" >&2
    echo "Run: ARCH=${ARCH} ./scripts/build-static.sh" >&2
    exit 1
  fi
}
