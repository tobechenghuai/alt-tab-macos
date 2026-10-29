import XCTest

final class UsageStatsStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        suiteName = "com.lwouis.alt-tab-macos.tests.usage-store.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testDisabledStoreRecordsOnlyAfterEnabling() {
        let store = UsageStatsStore(defaults: defaults, enabled: false)
        store.record("triggers", at: 1)
        store.flushNow()
        XCTAssertNil(defaults.object(forKey: "triggers"))
        store.setEnabled(true)
        store.record("triggers", at: 2)
        store.flushNow()
        XCTAssertEqual(store.timestamps("triggers"), [2])
        store.setEnabled(false)
        store.record("triggers", at: 3)
        store.flushNow()
        XCTAssertEqual(defaults.array(forKey: "triggers") as? [Int], [2])
    }

    func testDisablingPreservesHistoryAndBlocksEveryCounter() {
        defaults.set([1], forKey: "triggers")
        let store = UsageStatsStore(defaults: defaults, enabled: true)
        store.record("triggers", at: 2)
        store.setEnabled(false)
        for key in UsageStatsMaintenance.currentKeys { store.record(key, at: 3) }
        store.flushNow()
        XCTAssertEqual(store.timestamps("triggers"), [1, 2])
        XCTAssertNil(defaults.object(forKey: "searches"))
        XCTAssertNil(defaults.object(forKey: "triggersExtraShortcuts"))
    }

    func testClearRemovesPersistedCachedAndPendingHistoryAfterDelayedFlush() {
        for key in UsageStatsMaintenance.currentKeys + UsageStatsMaintenance.obsoleteKeys { defaults.set([1], forKey: key) }
        defaults.set("preserved", forKey: "unrelated")
        let store = UsageStatsStore(defaults: defaults, enabled: true, flushDelay: 0.02)
        XCTAssertEqual(store.timestamps("triggers"), [1])
        store.record("triggers", at: 2)
        let cleared = expectation(description: "Clear and pending flush finish")
        store.clearHistory {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                store.flushNow()
                for key in UsageStatsMaintenance.currentKeys + UsageStatsMaintenance.obsoleteKeys {
                    XCTAssertNil(self.defaults.object(forKey: key))
                    XCTAssertEqual(store.timestamps(key), [])
                }
                XCTAssertEqual(self.defaults.string(forKey: "unrelated"), "preserved")
                cleared.fulfill()
            }
        }
        wait(for: [cleared], timeout: 2)
    }

    func testClearAllowsNewHistoryAndRepeatedClears() {
        let store = UsageStatsStore(defaults: defaults, enabled: true)
        store.record("triggers", at: 1)
        let cleared = expectation(description: "Clear finishes")
        store.clearHistory { cleared.fulfill() }
        store.record("triggers", at: 2)
        store.flushNow()
        wait(for: [cleared], timeout: 2)
        XCTAssertEqual(defaults.array(forKey: "triggers") as? [Int], [2])
        let clearedAgain = expectation(description: "Repeated clear finishes")
        store.clearHistory { clearedAgain.fulfill() }
        store.flushNow()
        wait(for: [clearedAgain], timeout: 2)
        XCTAssertEqual(store.timestamps("triggers"), [])
    }

    func testClearPreservesDisabledState() {
        defaults.set([1], forKey: "triggers")
        let store = UsageStatsStore(defaults: defaults, enabled: false)
        let cleared = expectation(description: "Clear finishes")
        store.clearHistory { cleared.fulfill() }
        store.record("triggers", at: 2)
        store.flushNow()
        wait(for: [cleared], timeout: 2)
        XCTAssertNil(defaults.object(forKey: "triggers"))
    }

    func testPruneMigratesObsoleteHistoryAndRetainsCurrentTimestamps() {
        defaults.set([1, 10, 20], forKey: "triggers")
        defaults.set("malformed", forKey: "triggersTitles")
        let store = UsageStatsStore(defaults: defaults, enabled: false)
        store.prune(before: 10)
        store.flushNow()
        XCTAssertEqual(store.timestamps("triggers"), [10, 20])
        XCTAssertNil(defaults.object(forKey: "triggersTitles"))
    }

    func testMalformedHistoryCanBeCleared() {
        defaults.set("malformed", forKey: "searches")
        let store = UsageStatsStore(defaults: defaults, enabled: true)
        XCTAssertEqual(store.timestamps("searches"), [])
        let cleared = expectation(description: "Malformed history cleared")
        store.clearHistory { cleared.fulfill() }
        store.flushNow()
        wait(for: [cleared], timeout: 2)
        XCTAssertNil(defaults.object(forKey: "searches"))
    }
}
