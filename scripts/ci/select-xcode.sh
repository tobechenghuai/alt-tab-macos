#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/../.."

developerDirectory="$(xcode-select -p)"
export DEVELOPER_DIR="$developerDirectory"
xcodebuild -version
sdkVersion="$(xcrun --sdk macosx --show-sdk-version)"
if [[ ! "$sdkVersion" =~ ^([0-9]+)\. ]] || (( BASH_REMATCH[1] < 26 )); then
  printf 'A macOS SDK version of 26 or newer is required; found %s\n' "$sdkVersion" >&2
  exit 1
fi
printf 'Developer directory: %s\nmacOS SDK: %s\n' "$developerDirectory" "$sdkVersion"
for dependency in vendor/ShortcutRecorder/Package.swift vendor/AppCenter/Package.swift vendor/AppCenter/Frameworks/CrashReporter.xcframework/Info.plist; do
  [[ -f "$dependency" ]] || { printf 'Missing local dependency: %s\n' "$dependency" >&2; exit 1; }
done
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'DEVELOPER_DIR=%s\n' "$developerDirectory" >> "$GITHUB_ENV"
fi
python3 --version
