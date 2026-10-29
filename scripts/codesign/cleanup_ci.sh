#!/usr/bin/env bash

set +x
set -euo pipefail

signingDirectory="${1:-${ALT_TAB_SIGNING_DIR:-}}"
[[ -n "$signingDirectory" ]] || exit 0
temporaryRoot="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
[[ "${signingDirectory%/*}" == "${temporaryRoot%/}" ]] || exit 1
case "${signingDirectory##*/}" in
  alttab-signing.*) ;;
  *) printf 'Unexpected signing directory\n' >&2; exit 1 ;;
esac
[[ -d "$signingDirectory" ]] || exit 0
[[ ! -L "$signingDirectory" && -f "$signingDirectory/owned-by-alttab-ci" ]] || exit 1
status=0
if [[ -f "$signingDirectory/local.xcconfig.generated" ]]; then
  if [[ -f "$signingDirectory/local.xcconfig.original" ]]; then
    if cp "$signingDirectory/local.xcconfig.original" config/local.xcconfig; then
      rm -f "$signingDirectory/local.xcconfig.generated" || status=1
    else
      status=1
    fi
  else
    if rm -f config/local.xcconfig; then
      rm -f "$signingDirectory/local.xcconfig.generated" || status=1
    else
      status=1
    fi
  fi
fi
if [[ -f "$signingDirectory/signing.keychain-db" ]]; then
  if ! security delete-keychain "$signingDirectory/signing.keychain-db"; then
    security lock-keychain "$signingDirectory/signing.keychain-db" || true
    status=1
  fi
fi
if [[ $status -ne 0 ]]; then
  printf 'Signing cleanup incomplete; retained recovery directory: %s\n' "$signingDirectory" >&2
  exit "$status"
fi
if ! rm -rf "$signingDirectory"; then
  if [[ -d "$signingDirectory" && ! -L "$signingDirectory" ]]; then
    touch "$signingDirectory/owned-by-alttab-ci" || true
  fi
  printf 'Could not remove signing directory: %s\n' "$signingDirectory" >&2
  exit 1
fi
