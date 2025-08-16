#!/bin/bash

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

# Configuration
DEST="csv2img-mac.tar.gz"
BINARY_NAME="csv2img"

echo "🚀 Building Csv2Img $VERSION for macOS..."

# Building for Intel (x86_64) architecture
echo "📦 Building for Intel Mac..."
swift build -c release --arch x86_64
INTEL_BIN=".build/x86_64-apple-macosx/release/Csv2ImgCmd"

# Building for Apple Silicon (arm64) architecture
echo "📦 Building for Apple Silicon..."
swift build -c release --arch arm64
ARM_BIN=".build/arm64-apple-macosx/release/Csv2ImgCmd"

# Creating Universal Binary
echo "🔗 Creating Universal Binary..."
lipo -create "$INTEL_BIN" "$ARM_BIN" -output "$BINARY_NAME"

# Creating tarball
echo "📦 Creating tarball..."
tar czf "$DEST" "$BINARY_NAME"

# Calculate SHA256
SHA256=$(shasum -a 256 "$DEST" | cut -d' ' -f1)
echo "🔐 SHA256: $SHA256"

# Export for CI environment
if [ "$CI" = "true" ]; then
    echo "archive_name=$DEST" >> $GITHUB_ENV
    echo "sha256=$SHA256" >> $GITHUB_ENV
    echo "binary_name=$BINARY_NAME" >> $GITHUB_ENV
fi

# Cleanup temporary file
rm "$BINARY_NAME"

echo "✅ Release csv2img-$VERSION created successfully"
echo "📁 Output: $DEST"
