#!/bin/bash
set -euo pipefail
IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
command -v swiftc >/dev/null || { echo "需要 macOS Swift 工具链"; exit 1; }
cp "$IOS_DIR/tools/selftest.swift" "$TEST_DIR/main.swift"
swiftc "$TEST_DIR/main.swift" \
  "$IOS_DIR/AIFigure/Device/MiniPB.swift" \
  "$IOS_DIR/AIFigure/Device/AesCtr.swift" \
  "$IOS_DIR/AIFigure/Device/X25519.swift" -o "$TEST_DIR/protocol-tests"
"$TEST_DIR/protocol-tests"
cp "$IOS_DIR/tools/draft-selftest.swift" "$TEST_DIR/main.swift"
swiftc "$TEST_DIR/main.swift" "$IOS_DIR/AIFigure/App/OnboardingDraft.swift" -o "$TEST_DIR/draft-tests"
"$TEST_DIR/draft-tests"
swiftc -parse-as-library "$IOS_DIR/tools/collection-selftest.swift" \
  "$IOS_DIR/AIFigure/App/RemoteCollection.swift" \
  "$IOS_DIR/AIFigure/Server/ServerConfig.swift" \
  "$IOS_DIR/AIFigure/Server/APIClient.swift" \
  "$IOS_DIR/AIFigure/Content/Models.swift" -o "$TEST_DIR/collection-tests"
"$TEST_DIR/collection-tests"
swiftc -parse-as-library "$IOS_DIR/tools/device-client-selftest.swift" \
  "$IOS_DIR/AIFigure/Server/DeviceLabClient.swift" \
  "$IOS_DIR/AIFigure/Server/ChatHistory.swift" \
  "$IOS_DIR/AIFigure/Audio/SystemVolumePolicy.swift" -o "$TEST_DIR/device-client-tests"
"$TEST_DIR/device-client-tests"
swiftc -parse-as-library "$IOS_DIR/tools/ble-control-selftest.swift" \
  "$IOS_DIR/AIFigure/Device/BLEControlProtocol.swift" \
  "$IOS_DIR/AIFigure/Device/ProvisionSession.swift" \
  "$IOS_DIR/AIFigure/Device/MiniPB.swift" \
  "$IOS_DIR/AIFigure/Device/AesCtr.swift" \
  "$IOS_DIR/AIFigure/Device/X25519.swift" -o "$TEST_DIR/ble-control-tests"
"$TEST_DIR/ble-control-tests"
