#!/usr/bin/env bash

set +x
set -euo pipefail
umask 077

if [[ -n "${ALT_TAB_SIGNING_DIR:-}" ]]; then
  if [[ -f config/local.xcconfig ]]; then
    cp config/local.xcconfig "$ALT_TAB_SIGNING_DIR/local.xcconfig.original"
  fi
  touch "$ALT_TAB_SIGNING_DIR/local.xcconfig.generated"
fi

# Inject CI values via the same xcconfig override mechanism used locally.
# Xcode substitutes $(VAR) refs into Info.plist at build time.
cat > config/local.xcconfig <<EOF
CURRENT_PROJECT_VERSION = $(cat "$VERSION_FILE")
APPCENTER_SECRET = $APPCENTER_SECRET
EOF
