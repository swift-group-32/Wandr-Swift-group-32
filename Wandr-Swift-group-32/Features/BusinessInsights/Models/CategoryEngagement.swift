import Foundation

nonisolated struct CategoryEngagement: Codable, Identifiable, Equatable, Sendable {
    let category: String
    let completedQuests: Int
    let uniqueParticipants: Int

    var id: String { category }

    var name: String {
        switch category {
        case "park": "Parks"
        case "bar": "Bars"
        case "museum": "Museums"
        case "restaurant": "Restaurants"
        case "event": "Events"
        case "culture": "Culture"
        case "outdoors": "Outdoors"
        default: category.capitalized
        }
    }
}

nonisolated struct CategoryEngagementReport: Codable, Equatable, Sendable {
    let windowStart: Date
    let windowEnd: Date
    let generatedAt: Date
    let categories: [CategoryEngagement]

    var rankedCategories: [CategoryEngagement] {
        categories.sorted {
            if $0.completedQuests != $1.completedQuests {
                return $0.completedQuests > $1.completedQuests
            }
            if $0.uniqueParticipants != $1.uniqueParticipants {
                return $0.uniqueParticipants > $1.uniqueParticipants
            }
            return $0.category < $1.category
        }
    }

    var leaders: [CategoryEngagement] {
        guard let first = rankedCategories.first, first.completedQuests > 0 else { return [] }
        return rankedCategories.filter {
            $0.completedQuests == first.completedQuests && $0.uniqueParticipants == first.uniqueParticipants
        }
    }

    func rank(for category: CategoryEngagement) -> Int? {
        guard category.completedQuests > 0 else { return nil }
        return rankedCategories.firstIndex {
            $0.completedQuests == category.completedQuests && $0.uniqueParticipants == category.uniqueParticipants
        }.map { $0 + 1 }
    }

    var recommendation: String {
        guard let leader = leaders.first else {
            return "Not enough engagement data to recommend a category yet."
        }
        let names = leaders.map(\.name).joined(separator: ", ")
        if leaders.count > 1 {
            return "\(names) share the strongest engagement. Each has \(leader.completedQuests) completed quests from \(leader.uniqueParticipants) participants in this period."
        }
        return "\(leader.name) show the strongest engagement, with \(leader.completedQuests) completed quests from \(leader.uniqueParticipants) participants in this period."
    }

    static func decode(_ data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid report date")
        }
        return try decoder.decode(Self.self, from: data)
    }
}
