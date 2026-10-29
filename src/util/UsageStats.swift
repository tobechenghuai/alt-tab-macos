/// Local usage counters backed by a serialized store of Unix-second timestamps.
struct UsageStats {
    private static let store = UsageStatsStore(
        defaults: UserDefaults(suiteName: "\(App.bundleIdentifier).usage")!,
        enabled: Preferences.usageStatisticsEnabled)
    private static let maxAge: TimeInterval = 365 * 24 * 3600
    private(set) static var searchRecordedThisSession = false
    #if DEBUG
    static var qaPinned: [String: [Int]]?
    #endif

    static func recordTrigger(_ shortcutIndex: Int) {
        if shortcutIndex > 0 && shortcutIndex < Preferences.maxShortcutCount {
            SearchDiscoveryHint.shared.extraShortcutWasUsed()
        }
        guard Preferences.usageStatisticsEnabled else { return }
        let timestamp = Int(Date().timeIntervalSince1970)
        store.record("triggers", at: timestamp)
        if shortcutIndex > 0 && shortcutIndex < Preferences.maxShortcutCount {
            store.record("triggersExtraShortcuts", at: timestamp)
        }
    }

    static func recordSearchIfFirst() {
        guard !searchRecordedThisSession else { return }
        searchRecordedThisSession = true
        SearchDiscoveryHint.shared.searchWasUsed()
        guard Preferences.usageStatisticsEnabled else { return }
        store.record("searches", at: Int(Date().timeIntervalSince1970))
    }

    static func loadPreviousSearch(_ completion: @escaping (Bool?) -> Void) {
        store.previousUse("searches", completion: completion)
    }

    static func loadPreviousExtraShortcut(_ completion: @escaping (Bool?) -> Void) {
        store.previousUse("triggersExtraShortcuts", completion: completion)
    }

    static func resetSession() {
        searchRecordedThisSession = false
    }

    static func count(_ key: String, since date: Date) -> Int {
        #if DEBUG
        if let qaPinned { return (qaPinned[key] ?? []).count { $0 >= Int(date.timeIntervalSince1970) } }
        #endif
        return store.timestamps(key).count { $0 >= Int(date.timeIntervalSince1970) }
    }

    static func formatCount(_ n: Int) -> String { UsageStatsTestable.formatCount(n) }

    static func setEnabled(_ enabled: Bool) {
        store.setEnabled(enabled)
        SearchDiscoveryHint.shared.statisticsPreferenceChanged()
    }

    static func clearHistory(completion: @escaping () -> Void) {
        searchRecordedThisSession = false
        #if DEBUG
        qaPinned = nil
        #endif
        SearchDiscoveryHint.shared.clearUsageHistory()
        store.clearHistory(completion: completion)
    }

    static func prune() {
        store.prune(before: Int(Date().timeIntervalSince1970 - maxAge))
    }

    static func flushNow() {
        store.flushNow()
    }
}
