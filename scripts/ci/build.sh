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
  -xcconfig config/custom.xcconfig \
  CODE_SIGNING_ALLOWED=YES \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  "CURRENT_PROJECT_VERSION=0.0.$buildNumber"

app="DerivedData/Build/Products/Release/AltTab Custom.app"
python3 scripts/ci/verify_bundle.py "$app"
architecture="$(lipo -archs "$app/Contents/MacOS/AltTab Custom")"
if [[ "$architecture" != arm64 ]]; then
  printf 'Expected arm64-only executable; found %s\n' "$architecture" >&2
  exit 1
fi
codesign --verify --deep --strict "$app"
signature="$(codesign --display --verbose=4 "$app" 2>&1)"
if [[ "$signature" != *"Signature=adhoc"* ]]; then
  printf 'Expected an ad-hoc signature for the Custom build\n' >&2
  exit 1
fi

mkdir -p artifacts
ditto -c -k --keepParent "$app" artifacts/AltTab-Custom-arm64.zip
python3 scripts/ci/verify_archive.py artifacts/AltTab-Custom-arm64.zip
(
  cd artifacts
  shasum -a 256 AltTab-Custom-arm64.zip > SHA256SUMS.txt
  shasum -a 256 -c SHA256SUMS.txt
)
