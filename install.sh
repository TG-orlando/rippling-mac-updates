#!/bin/bash

# One-line installer for Mac Application Updater
# Usage: curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash

set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main"
SCRIPT_NAME="update-mac-apps.sh"
INSTALL_DIR="/usr/local/bin"
TEMP_DIR="/tmp/mac-app-updater-$$"

echo "=== Mac Application Updater - One-Line Installer ==="
echo "Downloading and executing updater script..."

# Cleanup function
cleanup() {
    cd / 2>/dev/null || true
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}

# Ensure cleanup happens on exit
trap cleanup EXIT

# Create temp directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download the main script
if ! curl -fsSL "${REPO_URL}/${SCRIPT_NAME}" -o "$SCRIPT_NAME"; then
    echo "ERROR: Failed to download script"
    exit 1
fi

# Make executable
chmod +x "$SCRIPT_NAME"

# Execute immediately
echo "Running update script..."
bash "$SCRIPT_NAME"

echo "=== Update Complete ==="
