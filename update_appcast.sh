#!/bin/zsh

# Use sparkle_sign.sh directly instead of the shell function
SPARKLE_SIGN="$HOME/Workspace/.zshrc/sparkle_sign.sh"
if [ ! -f "$SPARKLE_SIGN" ]; then
    echo "Error: sparkle_sign.sh not found at $SPARKLE_SIGN"
    exit 1
fi

# Automatically detect app name from Archives directory
APP_FILE=$(ls -1 ./Archives/ | grep '\.app$' | head -n 1)
if [ -n "$APP_FILE" ]; then
    APP_NAME=$(basename "$APP_FILE" .app)
    echo "Found app: $APP_NAME"
else
    echo "Error: No .app bundle found in Archives directory."
    exit 1
fi

DMG_NAME="$APP_NAME.dmg"

# Get Sign via command line using full path
EDSIGN=$("$SPARKLE_SIGN" "$APP_NAME" "$DMG_NAME" | tail -n 1)
echo "Signing with: $EDSIGN"

# Split EDSIGN into signature and length
signature=$(echo "$EDSIGN" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
length=$(echo "$EDSIGN" | grep -o 'length="[^"]*"' | cut -d'"' -f2)

PLIST_FILE="./Archives/$APP_NAME.app/Contents/Info.plist"
TEMPLATE_FILE="appcast.template.xml"
OUTPUT_FILE="appcast.xml"

# Check if Info.plist exists
if [ ! -f "$PLIST_FILE" ]; then
    echo "Error: Info.plist not found at $PLIST_FILE"
    exit 1
fi

# Extract version and build from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PLIST_FILE")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_FILE")

if [ -z "$VERSION" ] || [ -z "$BUILD" ]; then
    echo "Error: Could not extract version or build number from Info.plist"
    exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file $TEMPLATE_FILE not found"
    exit 1
fi

# Replace all occurrences of {version}, {build}, {edsign_signature}, and {edsign_length} in the template
sed -e "s|{version}|$VERSION|g" \
    -e "s|{build}|$BUILD|g" \
    -e "s|{edsign_signature}|$signature|g" \
    -e "s|{edsign_length}|$length|g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Updated appcast.xml with version $VERSION (build $BUILD)"
