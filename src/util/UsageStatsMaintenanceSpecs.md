# Obsolete usage history cleanup

- The startup prune runs maintenance on the existing usage write queue before age-based pruning.
- Maintenance removes `triggersAppIcons`, `triggersTitles`, and `triggersAutoSize`, including malformed values.
- Current trigger, search, and extra-shortcut histories are preserved, along with unrelated keys.
- Repeated launches are idempotent; missing keys cause no preference write.
- Any cached entries and pending writes for obsolete keys are discarded before flushing.

`UsageStatsMaintenanceTests.swift` uses isolated preference suites to verify deletion, preservation, and repeat execution.
