#!/bin/bash
set -e

APP_NAME="IDEGo"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME}..."
swift build -c release --disable-sandbox

echo "Creating App Bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy Executable
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/"

# Copy Resources if they exist
if [ -d "Resources" ]; then
    echo "Copying Resources..."
    cp -r Resources/* "${RESOURCES_DIR}/"
fi

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.zhangyu.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

echo "App Bundle created at ${APP_BUNDLE}"

# Create ZIP archive
ZIP_NAME="${APP_NAME}.zip"
echo "Creating ZIP archive ${ZIP_NAME}..."
rm -f "${ZIP_NAME}"
zip -r "${ZIP_NAME}" "${APP_BUNDLE}"

echo "Release package created at $(pwd)/${ZIP_NAME}"
