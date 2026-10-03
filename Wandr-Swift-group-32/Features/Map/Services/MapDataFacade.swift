import Foundation
import Supabase

@MainActor
protocol MapRemoteProviding {
    func nearbyQuests(point: MapPoint, radiusKm: Double) async throws -> [NearbyMapQuestDTO]
    func nearbyPlaces(point: MapPoint, radiusKm: Double) async throws -> [NearbyMapPlaceDTO]
    func neighborhoodActivity(days: Int) async throws -> NeighborhoodActivityReport
}

@MainActor
protocol MapDataProviding {
    func nearbyQuests(point: MapPoint, radiusKm: Double) async throws -> [MapQuest]
    func neighborhoodActivity(days: Int) async throws -> NeighborhoodActivityReport
}

/// Facade: the ViewModel sees map-ready geography and analytics, without knowing
/// about RPCs, DTO decoding, or the join between quests and places.
@MainActor
final class MapDataFacade: MapDataProviding {
    private let remote: any MapRemoteProviding

    init(remote: any MapRemoteProviding) { self.remote = remote }

    convenience init() { self.init(remote: SupabaseMapRemote()) }

    func nearbyQuests(point: MapPoint, radiusKm: Double) async throws -> [MapQuest] {
        guard point.isValid, radiusKm.isFinite, radiusKm > 0 else { throw MapDataError.invalidGeography }
        async let questsRequest = remote.nearbyQuests(point: point, radiusKm: radiusKm)
        async let placesRequest = remote.nearbyPlaces(point: point, radiusKm: radiusKm)
        let (quests, places) = try await (questsRequest, placesRequest)
        let coordinates = Dictionary(places.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return try quests.map { quest in
            guard let place = coordinates[quest.placeId] else {
                throw MapDataError.missingCoordinates
            }
            let coordinate = MapPoint(latitude: place.latitude, longitude: place.longitude)
            guard coordinate.isValid, quest.distanceKm.isFinite, quest.distanceKm >= 0 else {
                throw MapDataError.invalidGeography
            }
            return MapQuest(id: quest.id, title: quest.title, placeName: quest.placeName,
                            duration: quest.estimatedDuration ?? 0, distanceKm: quest.distanceKm,
                            point: coordinate)
        }.sorted { $0.distanceKm == $1.distanceKm ? $0.id.uuidString < $1.id.uuidString : $0.distanceKm < $1.distanceKm }
    }

    func neighborhoodActivity(days: Int) async throws -> NeighborhoodActivityReport {
        let report = try await remote.neighborhoodActivity(days: days)
        return NeighborhoodActivityReport(windowStart: report.windowStart, windowEnd: report.windowEnd,
            unassignedCompletions: report.unassignedCompletions,
            neighborhoods: report.neighborhoods.sorted {
                if $0.completedQuests != $1.completedQuests { return $0.completedQuests > $1.completedQuests }
                if $0.name != $1.name { return $0.name < $1.name }
                return $0.id.uuidString < $1.id.uuidString
            })
    }
}

private enum MapDataError: LocalizedError {
    case missingCoordinates, invalidGeography
    var errorDescription: String? { "Some quest locations could not be loaded. Please refresh." }
}

@MainActor
final class SupabaseMapRemote: MapRemoteProviding {
    private let client: SupabaseClient
    private let prepareSession: @MainActor () async throws -> Void
    private var authenticationTask: Task<Void, Error>?

    init(client: SupabaseClient = supabase,
         prepareSession: @escaping @MainActor () async throws -> Void = { try await signInTestUserIfNeeded() }) {
        self.client = client
        self.prepareSession = prepareSession
    }

    private func authenticate() async throws {
        if let authenticationTask { return try await authenticationTask.value }
        let task = Task { try await prepareSession() }
        authenticationTask = task
        defer { authenticationTask = nil }
        try await task.value
    }

    private struct NearbyParameters: Encodable {
        let p_lat: Double
        let p_lng: Double
        let p_radius_km: Double
    }

    func nearbyQuests(point: MapPoint, radiusKm: Double) async throws -> [NearbyMapQuestDTO] {
        try await authenticate()
        let response = try await client.rpc("nearby_quests", params: NearbyParameters(
            p_lat: point.latitude, p_lng: point.longitude, p_radius_km: radiusKm)).execute()
        return try decoder.decode([NearbyMapQuestDTO].self, from: response.data)
    }

    func nearbyPlaces(point: MapPoint, radiusKm: Double) async throws -> [NearbyMapPlaceDTO] {
        try await authenticate()
        let response = try await client.rpc("nearby_places", params: NearbyParameters(
            p_lat: point.latitude, p_lng: point.longitude, p_radius_km: radiusKm)).execute()
        return try decoder.decode([NearbyMapPlaceDTO].self, from: response.data)
    }

    func neighborhoodActivity(days: Int) async throws -> NeighborhoodActivityReport {
        try await authenticate()
        let response = try await client.rpc("neighborhood_quest_activity", params: ["p_days": days]).execute()
        return try NeighborhoodActivityReport.decode(response.data)
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
