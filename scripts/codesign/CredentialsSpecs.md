# Build credential handling

- Workflow-wide environment variables contain ordinary build settings. Credentials are mapped into the steps that consume them.
- The repository token has the `contents: write` permission needed for publishing; checkout leaves credentials out of the Git configuration.
- Environment reporting uses a fixed allowlist. Secret-consuming shell scripts disable command tracing before handling values.
- CI decodes the existing signing certificate inside a mode-700 temporary directory and removes the P12 file on exit.
- Each signing run imports that certificate into a separate temporary keychain protected by a random password. The user's default keychain and existing certificate search paths are preserved.
- Failure during import cleans up immediately. The workflow's `always()` step deletes the temporary keychain and restores an existing `config/local.xcconfig`, or removes the CI-generated file.
- Cleanup accepts only a directly owned directory beneath the runner's temporary root. Symlinks and parent traversal are rejected.
- A failed configuration restore/removal retains its completion marker and original backup. Keychain deletion is still attempted; a deletion failure also attempts to lock the retained keychain.
- A successful configuration restore/removal clears its marker, so a cleanup retry preserves subsequent local configuration changes. Any failed cleanup exits nonzero and reports the retained private directory for recovery.
- The recovery directory is removed after all preceding cleanup operations succeed. Retry with `scripts/codesign/cleanup_ci.sh "$ALT_TAB_SIGNING_DIR"` once the reported failure is resolved.
- If final directory removal partially deletes the ownership marker, cleanup recreates that marker in the retained private directory so the same boundary checks permit a retry.
- Developer ID, Team ID, and bundle ID retain their existing values.

Run `python3 scripts/tests/test_ci_credentials.py` for mock signing, configuration restoration/removal failures, keychain deletion failure and locking, directory removal failure, retry behavior, tracing, and workflow-scope checks. These tests use disposable files and fake signing/network tools.

Real code signing, Keychain search behavior, notarization, and publishing require a macOS runner. The workflow uses the temporary-keychain lifecycle described in [GitHub's Apple signing guidance](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications) and the step environment mechanism in [GitHub's secrets documentation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets).
