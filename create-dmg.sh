#!/bin/bash

# Check if the folder name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <folder-path>"
  exit 1
fi

FOLDER_PATH=$1
DMG_NAME="OllamaChat.dmg"

# Check if OllamaChat.dmg already exists in the current directory
if [ -f "$DMG_NAME" ]; then
  echo "Removing existing $DMG_NAME file..."
  rm "$DMG_NAME"
fi

# Run create-dmg with the provided folder path
create-dmg \
--volname "OllamaChat" \
--window-pos 200 120 \
--window-size 400 300 \
--icon-size 100 \
--icon "OllamaChat.app" 80 110 \
--hide-extension "OllamaChat.app" \
--app-drop-link 240 110 \
"$DMG_NAME" \
"$FOLDER_PATH"

# Check if create-dmg command succeeded
if [ $? -eq 0 ]; then
  open .
  echo "DMG created successfully."
else
  echo "Failed to create DMG."
fi