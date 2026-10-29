#!/bin/bash

python3 -m unittest discover -s scripts/tests -p 'test_*.py' || exit $?
python3 scripts/l10n/validate_localizations.py || exit $?
python3 scripts/assets/compile_illustrations.py --check || exit $?
python3 scripts/assets/test_compile_illustrations.py || exit $?

# Debug runs the `#if DEBUG` tests and preserves incremental compilation for local edits.
xcodebuild test \
  -project alt-tab-macos.xcodeproj \
  -scheme Test \
  -configuration Debug \
  -derivedDataPath DerivedData \
  "$@"
