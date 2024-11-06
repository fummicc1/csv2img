#!/bin/bash

set -e 

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

# Assuming building on macOS

DEST="csv2img-mac.tar.gz"

# Building for Intel (x86_64) architecture
echo "Building for Intel Mac..."
swift build -c release --arch x86_64
INTEL_BIN=".build/x86_64-apple-macosx/release/Csv2ImgCmd"

# Building for Apple Silicon (arm64) architecture
echo "Building for Apple Silicon..."
swift build -c release --arch arm64
ARM_BIN=".build/arm64-apple-macosx/release/Csv2ImgCmd"

# Creating Universal Binary
echo "Creating Universal Binary..."
lipo -create "$INTEL_BIN" "$ARM_BIN" -output "csv2img"

# Creating tarball
echo "Creating tarball..."
tar czf $DEST csv2img
# Remove temp file
rm csv2img

echo "SHA256 for Universal Binary:"
shasum -a 256 $DEST

echo "Release csv2img-$VERSION created successfully"
