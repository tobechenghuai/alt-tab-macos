# Local usage controls

- General settings expose a local usage statistics switch and a separate clear-history action with confirmation.
- Recording stays enabled by default for compatibility. The switch is persisted with app settings and applies immediately.
- Disabling stops new trigger, search, and extra-shortcut counter entries. Previously recorded history remains available until cleared or expired.
- Search hints keep session state while statistics are disabled; their exposure dates and usage flags are persisted only while statistics are enabled.
- Changing the switch reloads persisted hint state, discarding temporary observations made during the disabled period before persistence resumes.
- Clearing removes current and obsolete counter keys, memory caches, pending writes, and search-hint history. It preserves other settings and the statistics switch.
- Clear, record, policy changes, prune, and flush use one serial queue. Deferred flushes observe the cleared cache, and later events can start fresh history.
- Search-hint history reads and deferred writes carry a generation so callbacks scheduled before clearing cannot restore old history.
- About-window counts refresh after clearing. Existing 365-day retention and two-second write coalescing remain in effect.

`UsageStatsStoreTests.swift` covers disabling and re-enabling, saved history preservation, queued and delayed writes across clearing, repeated clearing, recording after clearing, and malformed data. `UsageStatsMaintenanceTests.swift` verifies that hint-history removal preserves the recording choice and other app settings.
