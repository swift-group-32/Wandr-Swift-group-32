import Foundation
import Supabase
import Testing
@testable import Wandr_Swift_group_32

// Opt-in tests against isolated PostgreSQL + PostgREST, using the real Supabase SDK.
// Never point these fixtures at the hosted project. See the shared backend repository's sql/BQ11.md for setup.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["WANDR_BQ11_TEST_URL"] != nil))
@MainActor
struct MapBackendIntegrationTests {
    private func remote() throws -> SupabaseMapRemote {
        let env = ProcessInfo.processInfo.environment
        let address = try #require(env["WANDR_BQ11_TEST_URL"])
        let url = try #require(URL(string: address))
        let token = try #require(env["WANDR_BQ11_TEST_TOKEN"])
        let client = SupabaseClient(supabaseURL: url, supabaseKey: token,
                                    options: .init(global: .init(headers: ["Authorization": "Bearer \(token)"])))
        return SupabaseMapRemote(client: client, prepareSession: {})
    }

    @Test func BQ11RanksActivityAcrossUsersUsingRealBackend() async throws {
        let facade = MapDataFacade(remote: try remote())
        let report = try await facade.neighborhoodActivity(days: 30)
        #expect(report.neighborhoods.map(\.name) == ["Test North", "Test South", "Test Zero"])
        #expect(report.neighborhoods.map(\.completedQuests) == [3, 1, 0])
        #expect(report.neighborhoods.first?.activeParticipants == 2)
        #expect(report.neighborhoods.first?.activePlaces == 2)
        #expect(report.unassignedCompletions == 1)
        #expect(abs(report.windowEnd.timeIntervalSince(report.windowStart) - 30 * 86_400) < 1)
    }

    @Test func nearbyContractReturnsCoordinatesDistancesAndRadiusFiltering() async throws {
        let facade = MapDataFacade(remote: try remote())
        let point = MapPoint(latitude: 4.61, longitude: -74.08)
        let narrow = try await facade.nearbyQuests(point: point, radiusKm: 1)
        let wider = try await facade.nearbyQuests(point: point, radiusKm: 5)
        #expect(!narrow.isEmpty && wider.count > narrow.count)
        #expect(narrow.allSatisfy { $0.distanceKm <= 1 })
        #expect(wider.allSatisfy { $0.distanceKm <= 5 })
        #expect(wider.map(\.distanceKm) == wider.map(\.distanceKm).sorted())
        #expect(narrow.first?.point == point)
    }

    @Test func realBackendEmptyNearbyResults() async throws {
        let result = try await MapDataFacade(remote: remote()).nearbyQuests(
            point: MapPoint(latitude: 0, longitude: 0), radiusKm: 1)
        #expect(result.isEmpty)
    }

    @Test func realBackendRejectsInvalidAnalyticsWindow() async throws {
        do {
            _ = try await remote().neighborhoodActivity(days: 0)
            Issue.record("Backend accepted an invalid window")
        } catch {
            #expect(error.localizedDescription.contains("between 1 and 365"))
        }
    }
}
