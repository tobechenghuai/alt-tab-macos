#!/usr/bin/env bash

set +x
set -euo pipefail
umask 077

certificateDirectory="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/alttab-certificate.XXXXXX")"
trap 'rm -rf "$certificateDirectory"' EXIT
certificateFile="$certificateDirectory/codesign"

# Recreate the certificate from the secure environment variable
printf '%s' "$APPLE_P12_CERTIFICATE" | base64 --decode > "$certificateFile.p12"

scripts/codesign/import_certificate_into_new_keychain.sh "$certificateFile" ""
