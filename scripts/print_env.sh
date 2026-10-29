#!/usr/bin/env bash

set +x
set -euo pipefail

for name in GITHUB_EVENT_BEFORE GITHUB_EVENT_AFTER XCODE_BUILD_PATH VERSION_FILE APP_NAME; do
  printf '%s=%s\n' "$name" "${!name-}"
done
jq --version
