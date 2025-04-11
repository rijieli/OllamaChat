#!/bin/zsh

# Usage:
# Step1: ./create-dmg.sh "AppName"
# Step2: sparkle-sign "AppName" "AppName.dmg"

# Check if app name is provided or try to find it in Archives
if [ -z "$1" ]; then
  # Look for .app bundle in Archives directory using ls and grep
  APP_FILE=$(ls -1 ./Archives/ | grep '\.app$' | head -n 1)
  if [ -n "$APP_FILE" ]; then
    APP_NAME=$(basename "$APP_FILE" .app)
    echo "Found app: $APP_NAME"
  else
    echo "Error: App name is required and no .app bundle found in Archives directory."
    echo "Usage: ./create-dmg.sh AppName"
    exit 1
  fi
else
  APP_NAME="$1"
fi

DMG_NAME="$APP_NAME.dmg"

# Check if the folder name is provided as second argument
if [ -z "$2" ]; then
  FOLDER_PATH="Archives/"
else
  FOLDER_PATH=$2
fi

# Check if DMG already exists in the current directory
if [ -f "$DMG_NAME" ]; then
  echo "Removing existing $DMG_NAME file..."
  rm "$DMG_NAME"
fi

# Run create-dmg with the provided folder path
create-dmg \
--volname "$APP_NAME" \
--window-pos 200 120 \
--window-size 400 300 \
--icon-size 100 \
--icon "$APP_NAME.app" 80 110 \
--hide-extension "$APP_NAME.app" \
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
