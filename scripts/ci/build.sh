#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/../.."
buildNumber="${GITHUB_RUN_NUMBER:-0}"
if [[ ! "$buildNumber" =~ ^[0-9]+$ ]]; then
  printf 'Build number must contain digits only\n' >&2
  exit 1
fi

xcodebuild \
  -project alt-tab-macos.xcodeproj \
  -scheme Release \
  -configuration Release \
  -derivedDataPath DerivedData \
  -xcconfig config/personal.xcconfig \
  CODE_SIGNING_ALLOWED=YES \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  "CURRENT_PROJECT_VERSION=0.0.$buildNumber"

app="DerivedData/Build/Products/Release/AltTab.app"
lipo -verify_arch arm64 "$app/Contents/MacOS/AltTab"
codesign --verify --deep --strict "$app"
signature="$(codesign --display --verbose=4 "$app" 2>&1)"
if [[ "$signature" != *"Signature=adhoc"* ]]; then
  printf 'Expected an ad-hoc signature for the personal build\n' >&2
  exit 1
fi

mkdir -p artifacts
ditto -c -k --keepParent "$app" artifacts/AltTab-personal-arm64.zip
(
  cd artifacts
  shasum -a 256 AltTab-personal-arm64.zip > AltTab-personal-arm64.zip.sha256
)
