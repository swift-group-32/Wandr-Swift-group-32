import Foundation
import CoreLocation

struct MapPoint: Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    static let bogota = MapPoint(latitude: 4.6097, longitude: -74.0817)
    var isValid: Bool {
        latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct MapQuest: Identifiable, Equatable {
    let id: UUID
    let title: String
    let placeName: String
    let duration: Int
    let distanceKm: Double
    let point: MapPoint
}

struct NeighborhoodActivity: Decodable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let city: String
    let latitude: Double
    let longitude: Double
    let completedQuests: Int
    let activeParticipants: Int
    let activePlaces: Int

    var point: MapPoint { MapPoint(latitude: latitude, longitude: longitude) }
}

struct NeighborhoodActivityReport: Decodable, Equatable {
    let windowStart: Date
    let windowEnd: Date
    let unassignedCompletions: Int
    let neighborhoods: [NeighborhoodActivity]

    // PostgreSQL timestamps may include fractional seconds or omit them.
    static func decode(_ data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "Invalid activity timestamp")
        }
        return try decoder.decode(Self.self, from: data)
    }
}

struct NearbyMapQuestDTO: Decodable {
    let id: UUID
    let title: String
    let placeId: UUID
    let placeName: String
    let estimatedDuration: Int?
    let distanceKm: Double
}

struct NearbyMapPlaceDTO: Decodable {
    let id: UUID
    let latitude: Double
    let longitude: Double
}
