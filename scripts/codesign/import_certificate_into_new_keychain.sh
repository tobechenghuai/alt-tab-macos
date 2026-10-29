#!/usr/bin/env bash

set +x
set -euo pipefail
umask 077

certificateFile="$1"
certificatePassword="$2"

temporaryRoot="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
signingDirectory="$(mktemp -d "${temporaryRoot%/}/alttab-signing.XXXXXX")"
touch "$signingDirectory/owned-by-alttab-ci"
keychain="$signingDirectory/signing.keychain-db"
cleanup_on_failure() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    scripts/codesign/cleanup_ci.sh "$signingDirectory" || true
  fi
  exit "$status"
}
trap cleanup_on_failure EXIT
keychainPassword="$(openssl rand -hex 32)"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'ALT_TAB_SIGNING_DIR=%s\n' "$signingDirectory" >> "$GITHUB_ENV"
fi

# create a keychain
security create-keychain -p "$keychainPassword" "$keychain"
# The default five-minute timeout can lock the key before tests and compilation finish.
security set-keychain-settings -lut 21600 "$keychain"
# Preserve the user's default keychain and existing certificate search paths.
keychains=()
security list-keychains -d user > "$signingDirectory/search-list"
while IFS= read -r entry; do
  entry="${entry#*\"}"
  entry="${entry%\"*}"
  if [[ -n "$entry" && "$entry" != "$keychain" ]]; then
    keychains+=("$entry")
  fi
done < "$signingDirectory/search-list"
if [[ ${#keychains[@]} -gt 0 ]]; then
  security list-keychains -d user -s "$keychain" "${keychains[@]}"
else
  security list-keychains -d user -s "$keychain"
fi
# unlock keychain
security unlock-keychain -p "$keychainPassword" "$keychain"
# import p12 into Keychain
security import "$certificateFile.p12" -k "$keychain" -P "$certificatePassword" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -s -k "$keychainPassword" "$keychain" > /dev/null
