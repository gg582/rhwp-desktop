#!/usr/bin/env bash
# Build rhwp-desktop from source and install it system-wide.
#
# Usage:
#   ./install.sh
#
# This must be run as root (e.g. sudo ./install.sh) because it writes to
# /opt and /usr. The build itself runs first, then the install step.
#
# Environment:
#   ARCH      Target architecture: x64 | arm64 (default: host)
#   PREFIX    Base directory for the application (default: /opt)
#   BIN_DIR   Directory for the launcher symlink (default: /usr/bin)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-/opt}"
APP_DIR="${PREFIX}/rhwp-desktop"
BIN_DIR="${BIN_DIR:-/usr/bin}"

cd "${ROOT_DIR}"

if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root. Example:" >&2
  echo "  sudo ./install.sh" >&2
  exit 1
fi

# Build the self-contained static bundle.
ARCH="${ARCH}" "${ROOT_DIR}/scripts/build-static.sh"

# Load the computed bundle path.
source "${ROOT_DIR}/scripts/lib/static.sh"

require_static_bundle

echo "[rhwp-desktop/install] installing to ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}"
cp -a "${BUNDLE_DIR}/." "${APP_DIR}/"
chown -R root:root "${APP_DIR}"

# The Chromium SUID sandbox helper must be setuid root if sandboxing is enabled.
chmod 4755 "${APP_DIR}/chrome-sandbox" 2>/dev/null || true

# System launcher script.
mkdir -p "${BIN_DIR}"
cat > "${BIN_DIR}/rhwp-desktop" <<EOF
#!/bin/sh
exec "${APP_DIR}/rhwp-desktop" "\$@"
EOF
chmod +x "${BIN_DIR}/rhwp-desktop"

# Icon (256x256 PNG).
ICON_SIZE=256
ICON_DIR="/usr/share/icons/hicolor/${ICON_SIZE}x${ICON_SIZE}/apps"
mkdir -p "${ICON_DIR}"
cp "${ROOT_DIR}/desktop/build-resources/icon.png" "${ICON_DIR}/rhwp-desktop.png"

# Desktop entry.
mkdir -p /usr/share/applications
cat > /usr/share/applications/rhwp-desktop.desktop <<'EOF'
[Desktop Entry]
Name=rhwp-desktop
Name[ko]=rhwp-desktop
Comment=HWP/HWPX document editor
Comment[ko]=HWP/HWPX 문서 편집기
Exec=/usr/bin/rhwp-desktop %F
Icon=rhwp-desktop
Type=Application
Categories=Office;WordProcessor;
MimeType=application/x-hwp;application/x-hwpx;application/haansofthwp;
Terminal=false
StartupNotify=true
StartupWMClass=rhwp-desktop
EOF

# Refresh desktop/icon caches when the tools are available.
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f /usr/share/icons/hicolor || true
fi

echo "[rhwp-desktop/install] installed ${APP_DIR}"
echo "[rhwp-desktop/install] launcher: ${BIN_DIR}/rhwp-desktop"
