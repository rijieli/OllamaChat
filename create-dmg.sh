#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Usage:
# ./create-dmg.sh [AppName] [ArchiveDirectory]
#
# Creates the DMG and immediately refreshes appcast.xml.

if [ $# -ge 2 ]; then
  ARCHIVE_DIR="$2"
else
  ARCHIVE_DIR="$SCRIPT_DIR/Archives"
fi

if [ ! -d "$ARCHIVE_DIR" ]; then
  echo "Error: Archive directory not found at $ARCHIVE_DIR"
  exit 1
fi

if [ $# -ge 1 ]; then
  APP_NAME="$1"
else
  APP_FILE=$(find "$ARCHIVE_DIR" -maxdepth 1 -type d -name '*.app' | sort | head -n 1)
  if [ -z "$APP_FILE" ]; then
    echo "Error: No .app bundle found in $ARCHIVE_DIR"
    echo "Usage: ./create-dmg.sh [AppName] [ArchiveDirectory]"
    exit 1
  fi
  APP_NAME=$(basename "$APP_FILE" .app)
  echo "Found app: $APP_NAME"
fi

APP_BUNDLE_PATH="$ARCHIVE_DIR/$APP_NAME.app"
if [ ! -d "$APP_BUNDLE_PATH" ]; then
  echo "Error: App bundle not found at $APP_BUNDLE_PATH"
  exit 1
fi

DMG_PATH="$SCRIPT_DIR/$APP_NAME.dmg"

if [ -f "$DMG_PATH" ]; then
  echo "Removing existing $DMG_PATH file..."
  rm "$DMG_PATH"
fi

create-dmg \
--volname "$APP_NAME" \
--window-pos 200 120 \
--window-size 400 300 \
--icon-size 100 \
--icon "$APP_NAME.app" 80 110 \
--hide-extension "$APP_NAME.app" \
--app-drop-link 240 110 \
"$DMG_PATH" \
"$ARCHIVE_DIR"

echo "DMG created successfully."
echo "Updating appcast.xml..."
"$SCRIPT_DIR/update_appcast.py" \
  --app-bundle "$APP_BUNDLE_PATH" \
  --dmg-path "$DMG_PATH"

open "$SCRIPT_DIR"
echo "appcast.xml updated successfully."
