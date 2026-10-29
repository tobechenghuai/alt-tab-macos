import Foundation

enum UsageStatsMaintenance {
    static let currentKeys = ["triggers", "searches", "triggersExtraShortcuts"]
    static let obsoleteKeys = ["triggersAppIcons", "triggersTitles", "triggersAutoSize"]
    static let discoveryKeys = ["searchDiscovery.usedExtra", "searchDiscovery.lastWasExtra", "searchDiscovery.hasSearched",
                                "searchDiscovery.exposures", "searchDiscovery.lastExposure"]

    static func removeObsoleteCounters(from defaults: UserDefaults) {
        for key in obsoleteKeys where defaults.object(forKey: key) != nil {
            defaults.removeObject(forKey: key)
        }
    }

    static func clearDiscoveryHistory(from defaults: UserDefaults) {
        for key in discoveryKeys { defaults.removeObject(forKey: key) }
    }
}
