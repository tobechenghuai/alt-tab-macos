import XCTest

final class UsageStatsMaintenanceTests: XCTestCase {
    func testOnlyObsoleteStyleHistoryIsRemoved() throws {
        let name = "com.lwouis.alt-tab-macos.tests.usage-maintenance.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        for key in UsageStatsMaintenance.obsoleteKeys { defaults.set([1, 2, 3], forKey: key) }
        defaults.set([4, 5], forKey: "triggers")
        defaults.set([6], forKey: "searches")
        defaults.set([7], forKey: "triggersExtraShortcuts")
        defaults.set("preserved", forKey: "futureSetting")
        UsageStatsMaintenance.removeObsoleteCounters(from: defaults)
        UsageStatsMaintenance.removeObsoleteCounters(from: defaults)
        for key in UsageStatsMaintenance.obsoleteKeys { XCTAssertNil(defaults.object(forKey: key)) }
        XCTAssertEqual(defaults.array(forKey: "triggers") as? [Int], [4, 5])
        XCTAssertEqual(defaults.array(forKey: "searches") as? [Int], [6])
        XCTAssertEqual(defaults.array(forKey: "triggersExtraShortcuts") as? [Int], [7])
        XCTAssertEqual(defaults.string(forKey: "futureSetting"), "preserved")
    }

    func testMalformedObsoleteValuesAreRemoved() throws {
        let name = "com.lwouis.alt-tab-macos.tests.usage-maintenance.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("malformed", forKey: "triggersTitles")
        UsageStatsMaintenance.removeObsoleteCounters(from: defaults)
        XCTAssertNil(defaults.object(forKey: "triggersTitles"))
        XCTAssertNil(defaults.object(forKey: "triggersAppIcons"))
    }

    func testDiscoveryHistoryClearPreservesPreferencesAndRecordingChoice() throws {
        let name = "com.lwouis.alt-tab-macos.tests.discovery-maintenance.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        for key in UsageStatsMaintenance.discoveryKeys { defaults.set("history", forKey: key) }
        defaults.set("false", forKey: "usageStatisticsEnabled")
        defaults.set("1", forKey: "crashPolicy")
        UsageStatsMaintenance.clearDiscoveryHistory(from: defaults)
        UsageStatsMaintenance.clearDiscoveryHistory(from: defaults)
        for key in UsageStatsMaintenance.discoveryKeys { XCTAssertNil(defaults.object(forKey: key)) }
        XCTAssertEqual(defaults.string(forKey: "usageStatisticsEnabled"), "false")
        XCTAssertEqual(defaults.string(forKey: "crashPolicy"), "1")
    }
}
