import Foundation
import SwiftData
import Testing
@testable import Wandr_Swift_group_32

@MainActor
struct BusinessInsightsOfflineTests {
    private final class Service: BusinessInsightsServing {
        var currentAccountID: String? = "account-a"
        var hasAccess = true
        var accessChecks = 0
        var reportCalls = 0
        var activations = 0
        var error: Error?
        var suspendReport = false
        var pendingReport: CheckedContinuation<CategoryEngagementReport, Error>?

        func hasBusinessAccess() async throws -> Bool {
            accessChecks += 1
            if let error { throw error }
            return hasAccess
        }
        func activate(code: String) async throws { activations += 1 }
        func fetchReport() async throws -> CategoryEngagementReport {
            reportCalls += 1
            if suspendReport {
                return try await withCheckedThrowingContinuation { pendingReport = $0 }
            }
            return BusinessInsightsOfflineTests.report()
        }
    }

    private func storage() throws -> BusinessInsightsStorage {
        let container = try ModelContainer(for: SavedBusinessReport.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return BusinessInsightsStorage(container: container)
    }

    private static func report(completions: Int = 3) -> CategoryEngagementReport {
        CategoryEngagementReport(windowStart: Date(timeIntervalSince1970: 1_790_812_800),
            windowEnd: Date(timeIntervalSince1970: 1_793_404_800), generatedAt: .now,
            categories: [CategoryEngagement(category: "park", completedQuests: completions, uniqueParticipants: 2)])
    }

    @Test func cacheExpiresAtFiveMinutesAndSaveReplacesTheSnapshot() throws {
        let container = try ModelContainer(for: SavedBusinessReport.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = BusinessInsightsStorage(container: container)
        let now = Date()
        try store.save(Self.report(), accountID: "a", now: now)
        #expect(store.isFresh(accountID: "a", now: now.addingTimeInterval(299)))
        #expect(!store.isFresh(accountID: "a", now: now.addingTimeInterval(300)))
        #expect(!store.isFresh(accountID: "a", now: now.addingTimeInterval(-1)))
        try store.save(Self.report(completions: 9), accountID: "a", now: now)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<SavedBusinessReport>()) == 1)
        #expect(try store.load(accountID: "a")?.categories.first?.completedQuests == 9)
        // A new storage instance has no memory cache, so this reads SwiftData.
        let reopened = BusinessInsightsStorage(container: container)
        #expect(try reopened.load(accountID: "a")?.categories.first?.completedQuests == 9)
        #expect(!reopened.isFresh(accountID: "a", now: now.addingTimeInterval(300)))
    }

    @Test func swiftDataSurvivesReopeningTheDiskStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("report.store")
        let report = Self.report()
        do {
            let container = try ModelContainer(for: SavedBusinessReport.self,
                configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
            let store = BusinessInsightsStorage(container: container)
            try store.save(report, accountID: "account-a")
        }
        let reopened = try ModelContainer(for: SavedBusinessReport.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let store = BusinessInsightsStorage(container: reopened)
        #expect(try store.load(accountID: "account-a") == report)
        #expect(try store.load(accountID: "account-b") == nil)
    }

    @Test func clearRemovesMemoryAndSwiftDataForTheRightAccount() throws {
        let store = try storage()
        try store.save(Self.report(), accountID: "a")
        try store.save(Self.report(), accountID: "b")
        try store.remove(accountID: "a")
        #expect(try store.load(accountID: "a") == nil)
        #expect(try store.load(accountID: "b") != nil)
        try store.clearAll()
        #expect(try store.load(accountID: "b") == nil)
        #expect(!store.isFresh(accountID: "b"))
    }

    @Test func freshCacheSkipsRequestsButManualRefreshBypassesIt() async throws {
        let service = Service()
        let model = BusinessInsightsViewModel(service: service, storage: try storage())
        await model.load()
        await model.load()
        #expect(service.accessChecks == 1)
        #expect(service.reportCalls == 1)
        await model.load(forceRefresh: true)
        #expect(service.accessChecks == 2)
        #expect(service.reportCalls == 2)
    }

    @Test func offlineLaunchReadsSavedReportAndReconnectionRefreshesIt() async throws {
        let store = try storage()
        let saved = Self.report(completions: 9)
        try store.save(saved, accountID: "account-a")
        let service = Service()
        let model = BusinessInsightsViewModel(service: service, storage: store)
        await model.appear(isConnected: false)
        #expect(model.report == saved)
        #expect(model.notice?.contains("offline") == true)
        #expect(model.notice?.contains("saved report from") == true)
        #expect(service.accessChecks == 0)
        await model.connectivityChanged(isConnected: true)
        #expect(service.reportCalls == 1)
        #expect(model.report?.categories.first?.completedQuests == 3)
        #expect(model.notice == nil)
    }

    @Test func offlineWithoutSavedDataDoesNotInventAReportOrActivate() async throws {
        let service = Service()
        let model = BusinessInsightsViewModel(service: service, storage: try storage())
        await model.load(isConnected: false)
        #expect(model.report == nil)
        #expect(model.notice?.contains("no saved report") == true)
        model.accessCode = "1234"
        await model.activate(isConnected: false)
        #expect(service.activations == 0)
        #expect(service.accessChecks == 0)
        #expect(model.access != .active)
    }

    @Test func requestFailureKeepsSavedReportEvenWhenNetworkMonitorSaysOnline() async throws {
        let store = try storage()
        let report = Self.report()
        try store.save(report, accountID: "account-a", now: .now.addingTimeInterval(-301))
        let service = Service()
        service.error = BusinessInsightsError.offline
        let model = BusinessInsightsViewModel(service: service, storage: store)
        await model.load(isConnected: true)
        #expect(model.report == report)
        #expect(model.notice?.contains("saved report from") == true)
        #expect(model.errorMessage != nil)
        #expect(!model.isWorking)
    }

    @Test func revokedAccessDeletesTheOfflineSnapshot() async throws {
        let store = try storage()
        try store.save(Self.report(), accountID: "account-a")
        let service = Service()
        service.hasAccess = false
        let model = BusinessInsightsViewModel(service: service, storage: store)
        await model.load(forceRefresh: true)
        #expect(model.access == .inactive)
        #expect(model.report == nil)
        #expect(try store.load(accountID: "account-a") == nil)
    }

    @Test func anotherAccountCannotSeeThePreviousAccountsReport() async throws {
        let store = try storage()
        let service = Service()
        let model = BusinessInsightsViewModel(service: service, storage: store)
        await model.load()
        service.currentAccountID = "account-b"
        await model.load(isConnected: false)
        #expect(model.report == nil)
        #expect(model.access == .unknown)
    }

    @Test func storageFailureStillDisplaysTheNetworkReport() async {
        let service = Service()
        let model = BusinessInsightsViewModel(service: service, storage: BusinessInsightsStorage(container: nil))
        await model.load()
        #expect(model.report != nil)
        #expect(model.notice?.contains("could not be saved") == true)
        #expect(model.errorMessage == nil)
    }

    @Test func hiddenScreenDoesNotRefreshOnReconnection() async throws {
        let service = Service()
        let model = BusinessInsightsViewModel(service: service, storage: try storage())
        await model.appear(isConnected: true)
        model.disappear()
        await model.connectivityChanged(isConnected: false)
        await model.connectivityChanged(isConnected: true)
        #expect(service.reportCalls == 1)
    }

    @Test func logoutDuringRequestCannotRestoreTheDeletedSnapshot() async throws {
        let store = try storage()
        let service = Service()
        service.suspendReport = true
        let model = BusinessInsightsViewModel(service: service, storage: store)
        let task = Task { await model.load() }
        for _ in 0..<100 where service.pendingReport == nil { await Task.yield() }
        let pending = try #require(service.pendingReport)
        try store.clearAll()
        service.currentAccountID = nil
        pending.resume(returning: Self.report())
        await task.value
        #expect(model.report == nil)
        #expect(try store.load(accountID: "account-a") == nil)
    }

    @Test func reconnectDuringRequestSchedulesOnlyOneRetry() async throws {
        let store = try storage()
        let service = Service()
        service.suspendReport = true
        let model = BusinessInsightsViewModel(service: service, storage: store)
        let task = Task { await model.appear(isConnected: true) }
        for _ in 0..<100 where service.pendingReport == nil { await Task.yield() }
        let pending = try #require(service.pendingReport)
        await model.connectivityChanged(isConnected: false)
        await model.connectivityChanged(isConnected: true)
        await model.connectivityChanged(isConnected: true)
        #expect(service.reportCalls == 1)
        service.suspendReport = false
        pending.resume(throwing: BusinessInsightsError.offline)
        await task.value
        for _ in 0..<100 where service.reportCalls < 2 { await Task.yield() }
        #expect(service.reportCalls == 2)
        #expect(model.report != nil)
    }
}
