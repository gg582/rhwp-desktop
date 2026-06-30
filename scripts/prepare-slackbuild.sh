#!/usr/bin/env bash
# Prepare SlackBuild distributable tarballs for x86_64 and aarch64.
#
# Usage:
#   ./scripts/prepare-slackbuild.sh
#
# This script:
#   1. Builds the static tarballs for x64 and arm64 (if missing)
#   2. Computes MD5SUMs and generates per-arch slackbuild/rhwp-desktop.info
#   3. Creates slackbuild/dist/rhwp-desktop-slackbuild-<version>-<arch>.tar.gz
#
# The resulting tarballs can be uploaded to a GitHub Release. Slackware users
# download the tarball matching their architecture, extract it, and run
# ./rhwp-desktop.SlackBuild.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

# Ensure the SlackBuild directory has a local icon copy.
SLACKBUILD_DIR="${ROOT_DIR}/slackbuild"
if [[ ! -f "${SLACKBUILD_DIR}/icon.png" ]]; then
  cp "${ROOT_DIR}/desktop/build-resources/icon.png" "${SLACKBUILD_DIR}/icon.png"
fi

DIST_DIR="${SLACKBUILD_DIR}/dist"
mkdir -p "${DIST_DIR}"

build_for_arch() {
  local electron_arch=$1
  local slackware_arch=$2

  # Set the target architecture before sourcing the helpers.
  ARCH="${electron_arch}"
  source "${ROOT_DIR}/scripts/lib/static.sh"

  if [[ ! -f "${TARBALL}" ]]; then
    ./scripts/build-static.sh
  fi

  local md5
  md5=$(md5sum "${TARBALL}" | cut -d' ' -f1)
  echo "[rhwp-desktop/slackbuild] ${slackware_arch} source md5: ${md5}"

  # Generate per-arch .info file.
  local info_file="${SLACKBUILD_DIR}/${PRGNAM:-rhwp-desktop}.info"
  cat > "${info_file}" <<EOF
PRGNAM="rhwp-desktop"
VERSION="${VERSION}"
HOMEPAGE="https://github.com/edwardkim/rhwp-desktop"
DOWNLOAD="https://github.com/edwardkim/rhwp-desktop/releases/download/v${VERSION}/rhwp-desktop-${VERSION}-linux-${electron_arch}.tar.gz"
MD5SUM="${md5}"
REQUIRES=""
MAINTAINER="Runable.app"
EMAIL="support@runable.app"
EOF

  # Create the SlackBuild distributable tarball.
  local slack_tarball="${DIST_DIR}/rhwp-desktop-slackbuild-${VERSION}-${slackware_arch}.tar.gz"
  echo "[rhwp-desktop/slackbuild] creating ${slack_tarball}..."

  cd "${SLACKBUILD_DIR}"
  tar -czf "${slack_tarball}" \
    --exclude='dist' \
    rhwp-desktop.SlackBuild \
    rhwp-desktop.info \
    rhwp-desktop.desktop \
    slack-desc \
    icon.png

  cd "${ROOT_DIR}"
  echo "[rhwp-desktop/slackbuild] done: ${slack_tarball}"
}

PRGNAM="rhwp-desktop"
VERSION="$(node -p "require('${ROOT_DIR}/desktop/package.json').version")"

build_for_arch x64 x86_64
build_for_arch arm64 aarch64
