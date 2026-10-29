# Feedback and crash-report privacy

- Feedback requests contain exactly the user-authored title and body, plus the selected feedback category. The public GitHub issue confirmation remains in place.
- The app provides no automatic diagnostic attachment builder, preview, toggle, or crash-attachment delegate callback.
- AppCenter crash-report consent and its ordinary crash report remain available under the existing crash policy.
- The vendored AppCenter channel drops `errorAttachment` logs before enqueueing and filters them again when loading persisted batches. Attachment-only batches are deleted locally; mixed batches upload their ordinary logs.
- This persisted-batch policy covers attachments queued by an earlier app version. The vendor refresh script reapplies `vendor/scripts/patches/appcenter-disable-attachments.diff` and fails if that patch becomes incompatible.

Verify the feedback request fields and inspect first launch, crash-report consent, and a persisted attachment-only/mixed queue on macOS. Actual network payload verification remains required before release.
