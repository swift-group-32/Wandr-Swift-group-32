import Foundation

struct ReviewContext: Identifiable, Hashable, Codable {
    let questId: String
    let title: String
    let placeName: String
    let address: String?
    let xpEarned: Int
    var id: String { questId }

    static let preview = ReviewContext(
        questId: "preview-bakery", title: "Taste Bogotá's best hidden bakery",
        placeName: "Bakery Quest", address: "Chapinero Alto, Bogotá", xpEarned: 50
    )
}

enum ReviewAccuracy: String, Codable, CaseIterable, Identifiable {
    case spotOn, mostly, notQuite
    var id: String { rawValue }
    var title: String {
        switch self {
        case .spotOn: "Spot on!"
        case .mostly: "Mostly"
        case .notQuite: "Not quite"
        }
    }
}

struct ReviewPhoto: Identifiable {
    let id = UUID()
    let data: Data
}

struct ReviewDraft: Codable {
    let context: ReviewContext
    let rating: Int
    let highlights: [String]
    let notes: String
    let featureOnDiscoveryMap: Bool
    let accuracy: ReviewAccuracy
}

struct ReviewSubmissionResult: Decodable {
    let reviewId: UUID
    let xpEarned: Int
    let alreadySubmitted: Bool
    let featureOnDiscoveryMap: Bool
}

struct ReviewSubmissionParameters: Encodable {
    let p_quest_id: String
    let p_rating: Int
    let p_notes: String
    let p_highlights: [String]
    let p_accuracy: String
    let p_feature_on_discovery_map: Bool
    let p_photo_paths: [String]
}
