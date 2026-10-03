import Combine
import Foundation
import Testing
@testable import Wandr_Swift_group_32

@MainActor
struct MapIntegrationTests {
    private final class Location: MapLocationProviding {
        @Published var state: MapLocationState = .denied
        var updates: AnyPublisher<MapLocationState, Never> { $state.eraseToAnyPublisher() }
        var started = false
        func start() { started = true }
        func stop() { started = false }
    }

    private final class Remote: MapRemoteProviding {
        var failNearby = false
        var failActivity = false
        var empty = false
        var missingCoordinates = false
        var invalidCoordinates = false
        var tiedLeaders = false
        var radii: [Double] = []
        var points: [MapPoint] = []
        let placeId = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
        func nearbyQuests(point: MapPoint, radiusKm: Double) async throws -> [NearbyMapQuestDTO] {
            radii.append(radiusKm)
            points.append(point)
            if failNearby { throw URLError(.notConnectedToInternet) }
            if empty { return [] }
            return [
                NearbyMapQuestDTO(id: UUID(), title: "Further quest", placeId: placeId,
                                  placeName: "Park", estimatedDuration: 45, distanceKm: 0.8),
                NearbyMapQuestDTO(id: UUID(), title: "Closer quest", placeId: placeId,
                                  placeName: "Park", estimatedDuration: nil, distanceKm: 0.2)
            ]
        }
        func nearbyPlaces(point: MapPoint, radiusKm: Double) async throws -> [NearbyMapPlaceDTO] {
            if missingCoordinates { return [] }
            return [NearbyMapPlaceDTO(id: placeId, latitude: invalidCoordinates ? 400 : 4.61, longitude: -74.08)]
        }
        func neighborhoodActivity(days: Int) async throws -> NeighborhoodActivityReport {
            if failActivity { throw URLError(.badServerResponse) }
            var json = empty ? Self.emptyJSON : Self.reportJSON
            if tiedLeaders { json = json.replacingOccurrences(of: "\"completed_quests\":1", with: "\"completed_quests\":3") }
            return try NeighborhoodActivityReport.decode(Data(json.utf8))
        }
        static let emptyJSON = """
        {"window_start":"2026-09-01T00:00:00Z","window_end":"2026-10-01T00:00:00Z",
         "unassigned_completions":0,"neighborhoods":[]}
        """
        static let reportJSON = """
        {"window_start":"2026-09-01T00:00:00.000000Z","window_end":"2026-10-01T00:00:00Z",
         "unassigned_completions":2,"neighborhoods":[
          {"id":"40000000-0000-0000-0000-000000000002","name":"Test South","city":"Bogotá",
           "latitude":4.59,"longitude":-74.08,"completed_quests":1,"active_participants":1,"active_places":1},
          {"id":"40000000-0000-0000-0000-000000000001","name":"Test North","city":"Bogotá",
           "latitude":4.61,"longitude":-74.08,"completed_quests":3,"active_participants":2,"active_places":2},
          {"id":"40000000-0000-0000-0000-000000000003","name":"Test Zero","city":"Bogotá",
           "latitude":4.60,"longitude":-74.08,"completed_quests":0,"active_participants":0,"active_places":0}]}
        """
    }

    @Test func deniedLocationStillLoadsFallbackQuestsAndBQ11ThroughFacade() async {
        let remote = Remote()
        let model = DiscoveryMapViewModel(facade: MapDataFacade(remote: remote), location: Location())
        await model.refresh()
        #expect(model.center == .bogota)
        #expect(!model.showsUserLocation)
        #expect(model.locationNotice?.contains("central Bogotá") == true)
        #expect(remote.points == [.bogota])
        #expect(model.quests.first?.title == "Closer quest")
        #expect(model.quests.first?.duration == 0)
        #expect(model.quests.first?.point == MapPoint(latitude: 4.61, longitude: -74.08))
        #expect(model.leadingNeighborhoods.first?.name == "Test North")
        #expect(model.activity?.unassignedCompletions == 2)
        #expect(!model.isLoadingNearby && !model.isLoadingActivity)
    }

    @Test func emptyResultsAreSuccessfulEmptyStates() async {
        let remote = Remote()
        remote.empty = true
        let model = DiscoveryMapViewModel(facade: MapDataFacade(remote: remote), location: Location())
        await model.refresh()
        #expect(model.quests.isEmpty && model.activeNeighborhoods.isEmpty)
        #expect(model.activity != nil)
        #expect(model.nearbyError == nil && model.activityError == nil)
    }

    @Test func analyticsFailureDoesNotHideNearbyQuestsAndCanRetry() async {
        let remote = Remote()
        remote.failActivity = true
        let model = DiscoveryMapViewModel(facade: MapDataFacade(remote: remote), location: Location())
        await model.refresh()
        #expect(!model.quests.isEmpty && model.nearbyError == nil)
        #expect(model.activityError != nil && model.activity == nil)
        remote.failActivity = false
        await model.loadActivity()
        #expect(model.activityError == nil && model.activity != nil)
    }

    @Test func nearbyFailureDoesNotHideBQ11AndCanRetry() async {
        let remote = Remote()
        remote.failNearby = true
        let model = DiscoveryMapViewModel(facade: MapDataFacade(remote: remote), location: Location())
        await model.refresh()
        #expect(model.nearbyError != nil && model.quests.isEmpty)
        #expect(model.activityError == nil && !model.leadingNeighborhoods.isEmpty)
        remote.failNearby = false
        await model.loadNearby()
        #expect(model.nearbyError == nil && !model.quests.isEmpty)
    }

    @Test func missingCoordinatesProduceRetryableErrorInsteadOfInvisibleQuests() async {
        let remote = Remote()
        remote.missingCoordinates = true
        let model = DiscoveryMapViewModel(facade: MapDataFacade(remote: remote), location: Location())
        await model.refresh()
        #expect(model.nearbyError != nil && model.quests.isEmpty)
        #expect(model.activity != nil)
    }

    @Test func invalidCoordinatesCannotReachMapKit() async {
        let remote = Remote()
        remote.invalidCoordinates = true
        let model = DiscoveryMapViewModel(facade: MapDataFacade(remote: remote), location: Location())
        await model.refresh()
        #expect(model.nearbyError != nil && model.quests.isEmpty)
        #expect(model.activity != nil)
    }

    @Test func tiedTopNeighborhoodsSharePartnershipPriority() async {
        let remote = Remote()
        remote.tiedLeaders = true
        let model = DiscoveryMapViewModel(facade: MapDataFacade(remote: remote), location: Location())
        await model.refresh()
        #expect(model.leadingNeighborhoods.map(\.name) == ["Test North", "Test South"])
    }

    @Test func radiusChangeQueriesTheChosenRadius() async {
        let remote = Remote()
        let model = DiscoveryMapViewModel(facade: MapDataFacade(remote: remote), location: Location())
        model.setRadius(1)
        for _ in 0..<1_000 {
            if remote.radii.last == 1 && !model.isLoadingNearby { break }
            await Task.yield()
        }
        #expect(model.radiusKm == 1)
        #expect(remote.radii.last == 1)
        model.setRadius(100)
        #expect(model.radiusKm == 1)
        model.stop()
    }

    @Test func GPSUpdatesReplaceFallbackAndStoppingPreventsNewQueries() async {
        let remote = Remote()
        let location = Location()
        let model = DiscoveryMapViewModel(facade: MapDataFacade(remote: remote), location: location)
        model.start()
        let point = MapPoint(latitude: 4.65, longitude: -74.06)
        location.state = .located(point, approximate: true)
        for _ in 0..<1_000 {
            if remote.points.last == point && !model.isLoadingNearby { break }
            await Task.yield()
        }
        #expect(model.center == point && model.showsUserLocation)
        #expect(remote.points.last == point)
        #expect(model.locationNotice?.contains("approximate") == true)
        model.stop()
        let count = remote.points.count
        location.state = .denied
        await Task.yield()
        #expect(remote.points.count == count)
        #expect(!location.started)
    }

    private final class DelayedFacade: MapDataProviding {
        var continuation: CheckedContinuation<[MapQuest], Never>?
        var calls = 0
        let latest = MapQuest(id: UUID(), title: "Latest", placeName: "Park", duration: 20,
                              distanceKm: 0.1, point: .bogota)
        func nearbyQuests(point: MapPoint, radiusKm: Double) async throws -> [MapQuest] {
            calls += 1
            if calls == 1 { return await withCheckedContinuation { continuation = $0 } }
            return [latest]
        }
        func neighborhoodActivity(days: Int) async throws -> NeighborhoodActivityReport {
            try NeighborhoodActivityReport.decode(Data(Remote.emptyJSON.utf8))
        }
    }

    @Test func obsoleteResponseCannotOverwriteLatestResults() async throws {
        let facade = DelayedFacade()
        let model = DiscoveryMapViewModel(facade: facade, location: Location())
        let old = Task { await model.loadNearby() }
        for _ in 0..<1_000 {
            if facade.continuation != nil { break }
            await Task.yield()
        }
        let continuation = try #require(facade.continuation)
        #expect(model.isLoadingNearby)
        model.setRadius(1)
        await model.loadNearby()
        continuation.resume(returning: [])
        await old.value
        #expect(model.quests.first?.id == facade.latest.id)
        #expect(!model.isLoadingNearby)
        model.stop()
    }

    @Test func invalidReportingTimestampIsRejected() {
        #expect(throws: (any Error).self) {
            try NeighborhoodActivityReport.decode(Data(Remote.emptyJSON.replacingOccurrences(of: "2026-10-01T00:00:00Z", with: "invalid").utf8))
        }
    }
}
