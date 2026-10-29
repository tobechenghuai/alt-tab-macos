#!/usr/bin/env bash

set +x
set -euo pipefail
umask 077

semanticRelease=$(npx semantic-release --dry-run --ci false)
version=$(echo "$semanticRelease" | sed -nE 's/.+The next release version is (.+)/\1/p')

echo "$version" > $VERSION_FILE
