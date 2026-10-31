import Foundation
import SwiftData

@Model
final class SavedBusinessReport {
    @Attribute(.unique) var accountID: String
    var windowStart: Date
    var windowEnd: Date
    var generatedAt: Date
    var savedAt: Date
    var categories: [CategoryEngagement]

    init(accountID: String, report: CategoryEngagementReport, savedAt: Date) {
        self.accountID = accountID
        self.windowStart = report.windowStart
        self.windowEnd = report.windowEnd
        self.generatedAt = report.generatedAt
        self.savedAt = savedAt
        self.categories = report.categories
    }

    var report: CategoryEngagementReport {
        CategoryEngagementReport(windowStart: windowStart, windowEnd: windowEnd,
                                 generatedAt: generatedAt, categories: categories)
    }
}

// One small snapshot: use SwiftData's main context, without a separate model actor.
@MainActor
final class BusinessInsightsStorage {
    static let shared = BusinessInsightsStorage(container: try? ModelContainer(
        for: SavedBusinessReport.self,
        configurations: ModelConfiguration("BusinessInsights", cloudKitDatabase: .none)
    ))

    private final class CachedReport {
        let report: CategoryEngagementReport
        let savedAt: Date
        init(_ report: CategoryEngagementReport, savedAt: Date) {
            self.report = report
            self.savedAt = savedAt
        }
    }

    private let cache = NSCache<NSString, CachedReport>()
    private let container: ModelContainer?
    // In-flight requests capture this value so logout cannot be undone by a late response.
    private(set) var generation = 0
    private let maxAge: TimeInterval = 5 * 60

    init(container: ModelContainer?) {
        self.container = container
        container?.mainContext.autosaveEnabled = false
    }

    func load(accountID: String) throws -> CategoryEngagementReport? {
        if let cached = cache.object(forKey: accountID as NSString) { return cached.report }
        guard let saved = try savedReport(accountID: accountID) else { return nil }
        cache.setObject(CachedReport(saved.report, savedAt: saved.savedAt), forKey: accountID as NSString)
        return saved.report
    }

    func isFresh(accountID: String, now: Date = .now) -> Bool {
        guard let savedAt = cache.object(forKey: accountID as NSString)?.savedAt else { return false }
        let age = now.timeIntervalSince(savedAt)
        return age >= 0 && age < maxAge
    }

    func save(_ report: CategoryEngagementReport, accountID: String, now: Date = .now) throws {
        cache.setObject(CachedReport(report, savedAt: now), forKey: accountID as NSString)
        guard let context = container?.mainContext else { throw StorageError.unavailable }
        do {
            if let saved = try savedReport(accountID: accountID) {
                saved.windowStart = report.windowStart
                saved.windowEnd = report.windowEnd
                saved.generatedAt = report.generatedAt
                saved.savedAt = now
                saved.categories = report.categories
            } else {
                context.insert(SavedBusinessReport(accountID: accountID, report: report, savedAt: now))
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func remove(accountID: String) throws {
        generation += 1
        cache.removeObject(forKey: accountID as NSString)
        guard let context = container?.mainContext else { return }
        if let saved = try savedReport(accountID: accountID) { context.delete(saved) }
        try context.save()
    }

    func clearAll() throws {
        generation += 1
        cache.removeAllObjects()
        guard let context = container?.mainContext else { return }
        for saved in try context.fetch(FetchDescriptor<SavedBusinessReport>()) { context.delete(saved) }
        try context.save()
    }

    private func savedReport(accountID: String) throws -> SavedBusinessReport? {
        guard let context = container?.mainContext else { throw StorageError.unavailable }
        var descriptor = FetchDescriptor<SavedBusinessReport>(predicate: #Predicate { $0.accountID == accountID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private enum StorageError: Error { case unavailable }
}
