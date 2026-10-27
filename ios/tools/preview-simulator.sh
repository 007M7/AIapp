#!/bin/bash
set -euo pipefail
IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
xcodebuild -project "$IOS_DIR/AIFigure.xcodeproj" -target AIFigure -configuration Debug \
  -sdk iphonesimulator CONFIGURATION_BUILD_DIR="$BUILD/products" \
  CODE_SIGNING_ALLOWED=NO build > "$IOS_DIR/preview-build.log" 2>&1
DEVICE="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(v["udid"] for rows in d["devices"].values() for v in rows if "iPhone" in v["name"]))')"
xcrun simctl boot "$DEVICE" || true
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl status_bar "$DEVICE" override --time '9:41' --batteryState charged --batteryLevel 100
xcrun simctl install "$DEVICE" "$BUILD/products/AIFigure.app"
mkdir -p "$IOS_DIR/preview"
for SCREEN in home connect device bluetooth; do
  ARG="--preview-$SCREEN"
  xcrun simctl launch --terminate-running-process "$DEVICE" com.aiapp.figure "$ARG"
  sleep 3
  xcrun simctl io "$DEVICE" screenshot "$IOS_DIR/preview/$SCREEN.png"
done
