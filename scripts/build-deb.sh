#!/usr/bin/env bash
# Build a single .deb package for Debian/Ubuntu from the static bundle.
#
# Usage:
#   ./scripts/build-deb.sh
#
# Requires:
#   fpm  (https://fpm.readthedocs.io/)
#   rpm  (for fpm's rpm support, even when building .deb)
#
# Install on Debian/Ubuntu:
#   sudo apt-get install -y ruby ruby-dev build-essential rpm
#   sudo gem install fpm

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/static.sh"

cd "${ROOT_DIR}"

if ! command -v fpm >/dev/null 2>&1; then
  echo "fpm is required. Install with:" >&2
  echo "  sudo apt-get install -y ruby ruby-dev build-essential rpm" >&2
  echo "  sudo gem install fpm" >&2
  exit 1
fi

# Ensure the static bundle exists.
if [[ ! -d "${BUNDLE_DIR}" ]]; then
  ./scripts/build-static.sh
fi
require_static_bundle

mkdir -p "${STATIC_DIR}"

DEB_FILE="${STATIC_DIR}/rhwp-desktop-${VERSION}-linux-${DEB_ARCH}.deb"

echo "[rhwp-desktop/deb] building ${DEB_FILE}..."

fpm \
  -s dir \
  -t deb \
  -n rhwp-desktop \
  -v "${VERSION}" \
  --architecture "${DEB_ARCH}" \
  --license MIT \
  --vendor "Runable.app" \
  --maintainer "Runable.app <support@runable.app>" \
  --url "https://github.com/edwardkim/rhwp-desktop" \
  --description "HWP/HWPX document editor" \
  --category office \
  --deb-priority optional \
  --depends "libc6 (>= 2.31)" \
  --depends "libgtk-3-0" \
  --depends "libnss3" \
  --after-install "${ROOT_DIR}/scripts/package-scripts/postinst.sh" \
  --before-remove "${ROOT_DIR}/scripts/package-scripts/prerm.sh" \
  -p "${DEB_FILE}" \
  "${BUNDLE_DIR}/"=/opt/rhwp-desktop \
  "${ROOT_DIR}/desktop/build-resources/icon.png"=/usr/share/icons/hicolor/256x256/apps/rhwp-desktop.png \
  "${ROOT_DIR}/scripts/package-scripts/rhwp-desktop.desktop"=/usr/share/applications/rhwp-desktop.desktop

echo "[rhwp-desktop/deb] done: ${DEB_FILE}"
