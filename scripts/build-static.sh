#!/usr/bin/env bash
# Static build wrapper for rhwp-desktop.
# Builds a self-contained directory + tarball that can be installed on Linux
# without npm, node, or build tools at runtime.
#
# Usage:
#   ./scripts/build-static.sh              # host architecture
#   ARCH=arm64 ./scripts/build-static.sh   # target architecture override
#
# Outputs:
#   dist-static/rhwp-desktop-<version>-linux-<arch>/
#   dist-static/rhwp-desktop-<version>-linux-<arch>.tar.gz
#
# Environment:
#   ARCH              Target architecture: x64 | arm64 (default: host)
#   OUTPUT_DIR        Base output directory (default: dist-static)
#   RHWP_BUILD_WASM=1 Run upstream WASM/UI sync before building
#   SKIP_NPM_CI=1     Skip npm ci (use when deps are already installed)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/static.sh"

cd "${ROOT_DIR}"

log() { echo "[rhwp-desktop/static] $*"; }

# Optionally rebuild WASM + UI from upstream rhwp.
if [[ "${RHWP_BUILD_WASM:-0}" == "1" ]]; then
  log "syncing upstream rhwp (WASM + UI)..."
  ./scripts/build-rhwp-wasm-and-sync.sh
fi

# Ensure the WASM core is present.
if [[ ! -f "${ROOT_DIR}/core/pkg/package.json" ]]; then
  echo "Missing core/pkg (@rhwp/core). Run one of:" >&2
  echo "  ./scripts/build-rhwp-wasm-and-sync.sh" >&2
  echo "  RHWP_BUILD_WASM=1 ./scripts/build-static.sh" >&2
  exit 1
fi

# Install UI dependencies and build production UI assets.
cd "${ROOT_DIR}/ui"
if [[ "${SKIP_NPM_CI:-0}" != "1" ]]; then
  log "installing UI dependencies..."
  npm ci
fi
log "building UI..."
npm run build

# Install desktop dependencies and compile the Electron main process.
cd "${ROOT_DIR}/desktop"
if [[ "${SKIP_NPM_CI:-0}" != "1" ]]; then
  log "installing desktop dependencies..."
  npm ci
fi
log "building desktop..."
npm run build
log "preparing icons..."
npm run prepare:icons

# Create the static (unpacked) Electron bundle for the target architecture.
log "creating static bundle with electron-builder (arch=${ARCH})..."
rm -rf "${ROOT_DIR}/desktop/release/linux-${ARCH}-unpacked"
npx electron-builder --linux dir --"${ARCH}" --publish never

# electron-builder uses linux-unpacked for x64 and linux-<arch>-unpacked otherwise.
if [[ "${ARCH}" == "x64" ]]; then
  UNPACKED="${ROOT_DIR}/desktop/release/linux-unpacked"
else
  UNPACKED="${ROOT_DIR}/desktop/release/linux-${ARCH}-unpacked"
fi
if [[ ! -d "${UNPACKED}" ]]; then
  echo "electron-builder did not produce ${UNPACKED}" >&2
  exit 1
fi

# Move the unpacked bundle to the final static directory.
rm -rf "${BUNDLE_DIR}"
mkdir -p "${STATIC_DIR}"
mv "${UNPACKED}" "${BUNDLE_DIR}"

# Add a convenience shell launcher inside the bundle.
cat > "${BUNDLE_DIR}/rhwp-desktop.sh" <<'EOF'
#!/bin/sh
# Convenience launcher for the static rhwp-desktop bundle.
# The real binary is named rhwp-desktop and lives next to this script.
exec "$(dirname "$0")/rhwp-desktop" "$@"
EOF
chmod +x "${BUNDLE_DIR}/rhwp-desktop.sh"

# Create the distributable tarball.
log "creating tarball..."
cd "${STATIC_DIR}"
tar -czf "${TARBALL}" "${BUNDLE_NAME}"

log "done"
log "bundle:  ${BUNDLE_DIR}"
log "tarball: ${TARBALL}"
