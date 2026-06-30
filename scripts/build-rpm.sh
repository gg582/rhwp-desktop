#!/usr/bin/env bash
# Build a single .rpm package for Fedora/RHEL from the static bundle.
#
# Usage:
#   ./scripts/build-rpm.sh
#
# Requires:
#   fpm  (https://fpm.readthedocs.io/)
#   rpm  (rpmbuild is invoked by fpm)
#
# Install on Fedora/RHEL:
#   sudo dnf install -y ruby ruby-devel gcc make rpm-build
#   sudo gem install fpm

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/static.sh"

cd "${ROOT_DIR}"

if ! command -v fpm >/dev/null 2>&1; then
  echo "fpm is required. Install with:" >&2
  echo "  sudo dnf install -y ruby ruby-devel gcc make rpm-build" >&2
  echo "  sudo gem install fpm" >&2
  exit 1
fi

# Ensure the static bundle exists.
if [[ ! -d "${BUNDLE_DIR}" ]]; then
  ./scripts/build-static.sh
fi
require_static_bundle

mkdir -p "${STATIC_DIR}"

RPM_FILE="${STATIC_DIR}/rhwp-desktop-${VERSION}-linux-${RPM_ARCH}.rpm"

echo "[rhwp-desktop/rpm] building ${RPM_FILE}..."

fpm \
  -s dir \
  -t rpm \
  -n rhwp-desktop \
  -v "${VERSION}" \
  --architecture "${RPM_ARCH}" \
  --license MIT \
  --vendor "Runable.app" \
  --maintainer "Runable.app <support@runable.app>" \
  --url "https://github.com/edwardkim/rhwp-desktop" \
  --description "HWP/HWPX document editor" \
  --category Applications/Office \
  --depends "glibc >= 2.31" \
  --depends "gtk3" \
  --depends "nss" \
  --rpm-autoreqprov no \
  --after-install "${ROOT_DIR}/scripts/package-scripts/postinst.sh" \
  --before-remove "${ROOT_DIR}/scripts/package-scripts/prerm.sh" \
  -p "${RPM_FILE}" \
  "${BUNDLE_DIR}/"=/opt/rhwp-desktop \
  "${ROOT_DIR}/desktop/build-resources/icon.png"=/usr/share/icons/hicolor/256x256/apps/rhwp-desktop.png \
  "${ROOT_DIR}/scripts/package-scripts/rhwp-desktop.desktop"=/usr/share/applications/rhwp-desktop.desktop

echo "[rhwp-desktop/rpm] done: ${RPM_FILE}"
