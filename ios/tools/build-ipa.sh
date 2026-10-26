#!/bin/bash
# macOS 单一构建入口：生成工程、自测、编译、打包、来源记录。
set -euo pipefail
IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$IOS_DIR/dist"
CONFIGURATION="${BUILD_CONFIGURATION:-Release}"
case "$CONFIGURATION" in Debug|Release) ;; *) echo "Unsupported configuration"; exit 1 ;; esac
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
for tool in xcodegen xcodebuild swiftc zip shasum; do
  command -v "$tool" >/dev/null || { echo "缺少工具：$tool"; exit 1; }
done
(cd "$IOS_DIR" && xcodegen generate)
bash "$IOS_DIR/tools/run-selftests.sh"
xcodebuild -project "$IOS_DIR/AIFigure.xcodeproj" \
  -target AIFigure -configuration "$CONFIGURATION" -sdk iphoneos \
  CONFIGURATION_BUILD_DIR="$BUILD/products" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build 2>&1 | tee "$IOS_DIR/build.log"
APP="$BUILD/products/AIFigure.app"
[ -d "$APP" ] || { echo "构建失败：未找到应用"; exit 1; }
/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$APP/Info.plist"
/usr/libexec/PlistBuddy -c "Print :NSBluetoothAlwaysUsageDescription" "$APP/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist")"
mkdir -p "$BUILD/package/Payload"
cp -R "$APP" "$BUILD/package/Payload/"
(cd "$BUILD/package" && zip -qry AIFigure-unsigned.ipa Payload)
SHA="$(git -C "$IOS_DIR" rev-parse HEAD)"
DIRTY=false
[ -z "$(git -C "$IOS_DIR" status --porcelain)" ] || DIRTY=true
{
  printf 'commit=%s\ndirty=%s\nversion=%s\nconfiguration=%s\nbuilt_at_utc=%s\n' "$SHA" "$DIRTY" "$VERSION" "$CONFIGURATION" "$(date -u +%FT%TZ)"
  xcodebuild -version
  (cd "$BUILD/package" && shasum -a 256 AIFigure-unsigned.ipa)
} > "$BUILD/package/build-metadata.txt"
# 所有检查成功之后才替换本地产物，失败保留旧成功包。
mkdir -p "$OUT"
mv "$BUILD/package/AIFigure-unsigned.ipa" "$OUT/AIFigure-unsigned.ipa"
mv "$BUILD/package/build-metadata.txt" "$OUT/build-metadata.txt"
echo "完成：$OUT/AIFigure-unsigned.ipa（未签名；安装仍需验收）"
