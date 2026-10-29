#!/usr/bin/env bash

set +x
set -euo pipefail
umask 077

certificateDirectory="$(mktemp -d "${TMPDIR:-/tmp}/alttab-certificate.XXXXXX")"
trap 'rm -rf "$certificateDirectory"' EXIT
certificateFile="$certificateDirectory/codesign"
certificatePassword=$(openssl rand -base64 12)

scripts/codesign/generate_selfsigned_certificate.sh "$certificateFile" "$certificatePassword"
scripts/codesign/import_certificate_into_main_keychain.sh "$certificateFile" "$certificatePassword"
