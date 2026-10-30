import Foundation

nonisolated struct ActivityInsightsStorage {

    static let fileName = "inactive_users_report.json"

    static func save(_ report: InactiveUsersReport) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = paths[0].appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(report)
            let text = String(data: data, encoding: .utf8) ?? ""
            try text.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Could not save the report:", error)
        }
    }

    static func load() -> InactiveUsersReport? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = paths[0].appendingPathComponent(fileName)
        do {
            let text = try String(contentsOf: filePath, encoding: .utf8)
            return try JSONDecoder().decode(InactiveUsersReport.self, from: Data(text.utf8))
        } catch {
            return nil
        }
    }
}


class CachedReport {
    let report: InactiveUsersReport

    init(report: InactiveUsersReport) {
        self.report = report
    }
}

class ActivityInsightsCache {

    static let shared = ActivityInsightsCache()

    let cache = NSCache<NSString, CachedReport>()
    let key: NSString = "inactive_users_report"

    let maxAge: TimeInterval = 5 * 60

    func get() -> InactiveUsersReport? {
        cache.object(forKey: key)?.report
    }

    func save(_ report: InactiveUsersReport) {
        cache.setObject(CachedReport(report: report), forKey: key)
    }

    func isFresh() -> Bool {
        guard let report = get() else { return false }
        return Date().timeIntervalSince(report.date) < maxAge
    }
}
