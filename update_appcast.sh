#!/bin/bash

PLIST_FILE="./Archives/OllamaChat.app/Contents/Info.plist"
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

# Replace all occurrences of {version} and {build} in the template
sed -e "s/{version}/$VERSION/g" \
    -e "s/{build}/$BUILD/g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Updated appcast.xml with version $VERSION (build $BUILD)"
