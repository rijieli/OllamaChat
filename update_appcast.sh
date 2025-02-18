#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <version> <build>"
    exit 1
fi

VERSION=$1
BUILD=$2
TEMPLATE_FILE="appcast.template.xml"
OUTPUT_FILE="appcast.xml"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file $TEMPLATE_FILE not found"
    exit 1
fi

# Replace all occurrences of {version} and {build} in the template
sed -e "s/{version}/$VERSION/g" \
    -e "s/{build}/$BUILD/g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Updated appcast.xml with version $VERSION (build $BUILD)"
