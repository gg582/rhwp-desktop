#!/bin/sh
set -e

APP_DIR=/opt/rhwp-desktop

# Launcher symlink.
ln -sf "${APP_DIR}/rhwp-desktop" /usr/bin/rhwp-desktop

# Chromium SUID sandbox helper (optional; the app disables sandbox by default).
chmod 4755 "${APP_DIR}/chrome-sandbox" 2>/dev/null || true

# Refresh caches when available.
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f /usr/share/icons/hicolor || true
fi
