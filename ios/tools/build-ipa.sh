#!/bin/bash
# 在任意一台 Mac 上出「未签名 ipa」,之后拷到 Windows 用 Sideloadly 签名安装。
#
# 为什么不签名:Sideloadly 用你的 Apple ID 自己签;Xcode 侧签名反而会被重签覆盖。
# 用 -target 而不是 -scheme:手写工程没有共享 scheme,不依赖先开过 Xcode。
#
# 用法(Mac 上,本仓库任意位置):
#   bash ios/tools/build-ipa.sh
# 产物:ios/dist/AIFigure-unsigned.ipa
set -euo pipefail

IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="$IOS_DIR/AIFigure.xcodeproj"
OUT="$IOS_DIR/dist"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

# 工程由 XcodeGen 从 project.yml 生成(单一来源,同 jev 范式);没有 xcodeproj 就现场生成
if [ ! -d "$PROJ" ]; then
  command -v xcodegen >/dev/null || { echo "需要 xcodegen:brew install xcodegen"; exit 1; }
  (cd "$IOS_DIR" && xcodegen generate)
fi

echo "── 编译(Release, iPhoneOS, 不签名)"
# 注意:-target 不能与 -derivedDataPath 同用(xcodebuild 会报 exit 64);
# 用 CONFIGURATION_BUILD_DIR 定点输出到临时目录。
xcodebuild -project "$PROJ" \
  -target AIFigure \
  -configuration Release \
  -sdk iphoneos \
  CONFIGURATION_BUILD_DIR="$BUILD/products" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  build

APP="$BUILD/products/AIFigure.app"
[ -d "$APP" ] || { echo "构建失败:没找到 .app 产物"; exit 1; }

echo "── 打包 ipa"
rm -rf "$OUT"
mkdir -p "$OUT/Payload"
cp -R "$APP" "$OUT/Payload/"
(cd "$OUT" && zip -qry AIFigure-unsigned.ipa Payload && rm -rf Payload)

echo "── 完成:$OUT/AIFigure-unsigned.ipa"
echo "   下一步:拷到 Windows → Sideloadly 签名安装(见 ios/README.md §4)"
