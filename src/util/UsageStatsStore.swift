import Foundation

/// The queue owns recording policy, cached history, and persistence so a clear operation also covers pending writes.
final class UsageStatsStore {
    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "UsageStats.writeQueue", qos: .utility)
    private let flushDelay: TimeInterval
    private var enabled: Bool
    private var cache = [String: [Int]]()
    private var dirty = Set<String>()
    private var flushScheduled = false

    init(defaults: UserDefaults, enabled: Bool, flushDelay: TimeInterval = 2) {
        self.defaults = defaults
        self.enabled = enabled
        self.flushDelay = flushDelay
    }

    func setEnabled(_ enabled: Bool) {
        queue.async { self.enabled = enabled }
    }

    func record(_ key: String, at timestamp: Int) {
        queue.async {
            guard self.enabled else { return }
            self.load(key)
            self.cache[key, default: []].append(timestamp)
            self.dirty.insert(key)
            guard !self.flushScheduled else { return }
            self.flushScheduled = true
            self.queue.asyncAfter(deadline: .now() + self.flushDelay) { self.flush() }
        }
    }

    func timestamps(_ key: String) -> [Int] {
        queue.sync { load(key) }
    }

    func previousUse(_ key: String, completion: @escaping (Bool?) -> Void) {
        queue.async {
            let raw = self.defaults.object(forKey: key)
            let used = raw == nil ? false : (raw as? [Int]).map { !$0.isEmpty }
            DispatchQueue.main.async { completion(used) }
        }
    }

    func prune(before cutoff: Int) {
        queue.async {
            UsageStatsMaintenance.removeObsoleteCounters(from: self.defaults)
            for key in UsageStatsMaintenance.obsoleteKeys {
                self.cache[key] = nil
                self.dirty.remove(key)
            }
            for key in UsageStatsMaintenance.currentKeys {
                let timestamps = self.load(key)
                let pruned = timestamps.filter { $0 >= cutoff }
                guard pruned.count != timestamps.count else { continue }
                self.cache[key] = pruned
                self.dirty.insert(key)
            }
            self.flush()
        }
    }

    func clearHistory(completion: @escaping () -> Void) {
        queue.async {
            self.cache.removeAll()
            self.dirty.removeAll()
            for key in UsageStatsMaintenance.currentKeys + UsageStatsMaintenance.obsoleteKeys {
                self.defaults.removeObject(forKey: key)
            }
            DispatchQueue.main.async(execute: completion)
        }
    }

    func flushNow() {
        queue.sync { flush() }
    }

    @discardableResult
    private func load(_ key: String) -> [Int] {
        if let timestamps = cache[key] { return timestamps }
        let timestamps = defaults.object(forKey: key) as? [Int] ?? []
        cache[key] = timestamps
        return timestamps
    }

    private func flush() {
        flushScheduled = false
        for key in dirty { defaults.set(cache[key] ?? [], forKey: key) }
        dirty.removeAll()
    }
}
