import Foundation
import Testing
@testable import Wandr_Swift_group_32

@MainActor
struct LowUseCategoriesTests {
    @Test func preservesTheKotlinRPCContract() throws {
        let rows = try LowUseCategoriesService.decode(Data("""
        [{
            "tag_id": "tag-a", "tag_name": "Museos", "total_starts": 11,
            "average_per_week": 2.75, "weekly_breakdown": [
                {"week_start": "2026-10-26", "starts": 0},
                {"week_start": "2026-11-02", "starts": 4},
                {"week_start": "2026-11-09", "starts": 3},
                {"week_start": "2026-11-16", "starts": 4}
            ]
        }]
        """.utf8))

        #expect(rows.first?.id == "tag-a")
        #expect(rows.first?.tagName == "Museos")
        #expect(rows.first?.totalStarts == 11)
        #expect(rows.first?.averagePerWeek == 2.75)
        #expect(rows.first?.weeklyBreakdown.map(\.starts) == [0, 4, 3, 4])
        #expect(rows.first?.weeklyBreakdown.first?.weekStart == "2026-10-26")
        #expect(try LowUseCategoriesService.decode(Data("[]".utf8)).isEmpty)
    }

    @Test func reopensOfflineAndRefreshesOnReconnect() async throws {
        let (service, store, directory) = setup()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storedAt = Date(timeIntervalSince1970: 100)
        let initial = LowUseCategoriesViewModel(service: service, store: store)

        service.response = [category]
        await initial.load(connected: true, now: storedAt)
        await initial.load(connected: true, now: storedAt.addingTimeInterval(2))
        #expect(service.requests == 1)

        let reopened = LowUseCategoriesViewModel(
            service: service, store: LowUseCategoriesStore(directory: directory)
        )
        await reopened.load(connected: false)
        #expect(reopened.status == .offline)
        #expect(reopened.report?.updatedAt == storedAt)
        #expect(reopened.report?.categories == [category])

        service.response = []
        await reopened.load(connected: true, now: storedAt.addingTimeInterval(3))
        #expect(service.requests == 2)
        #expect(reopened.status == .ready)
        #expect(reopened.report?.categories == [])
    }

    @Test func keepsSavedReportForNetworkErrorsAndClearsItForDeniedAccess() async throws {
        let (service, store, directory) = setup()
        defer { try? FileManager.default.removeItem(at: directory) }
        let account = try #require(service.currentAccount)
        let model = LowUseCategoriesViewModel(service: service, store: store)
        service.response = [category]
        await model.load(connected: true)

        service.error = URLError(.notConnectedToInternet)
        await model.load(connected: true, force: true)
        #expect(model.status == .failed)
        #expect(model.report?.categories == [category])

        service.error = LowUseCategoriesError.accessDenied
        await model.load(connected: true, force: true)
        #expect(model.status == .accessDenied)
        #expect(model.report == nil)
        #expect(store.load(for: account) == nil)
    }

    @Test func doesNotShowAnotherAccountsReportOffline() async throws {
        let (service, store, directory) = setup()
        defer { try? FileManager.default.removeItem(at: directory) }
        let account = try #require(service.currentAccount)
        let model = LowUseCategoriesViewModel(service: service, store: store)

        await model.load(connected: false)
        #expect(model.status == .offline)
        #expect(model.report == nil)
        #expect(service.requests == 0)

        service.response = [category]
        await model.load(connected: true)
        service.currentAccount = UUID()
        await model.load(connected: false)
        #expect(model.status == .offline)
        #expect(model.report == nil)
        #expect(store.load(for: account)?.categories == [category])

        try store.clear()
        #expect(store.load(for: account) == nil)
    }

    private let category = LowUseCategory(
        tagId: "tag-a", tagName: "Museos", totalStarts: 2, averagePerWeek: 0.5,
        weeklyBreakdown: [.init(weekStart: "2026-11-02", starts: 2)]
    )

    private func setup() -> (Stub, LowUseCategoriesStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return (Stub(), LowUseCategoriesStore(directory: directory), directory)
    }

    private final class Stub: LowUseCategoriesServing {
        var currentAccount: UUID? = UUID()
        var response: [LowUseCategory] = []
        var error: (any Error)?
        var requests = 0

        func fetch(for account: UUID) async throws -> [LowUseCategory] {
            requests += 1
            if let error { throw error }
            return response
        }
    }
}
