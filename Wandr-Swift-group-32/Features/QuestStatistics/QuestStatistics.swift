import Foundation

nonisolated struct QuestStatisticsCompletion: Decodable, Sendable {
    struct Quest: Decodable, Sendable {
        let place: Place?
    }

    struct Place: Decodable, Sendable {
        let id: String
        let category: String?
        let latitude: Double?
        let longitude: Double?
    }

    let completedAt: Date?
    let quest: Quest?
}

nonisolated struct QuestStatistics: Codable, Equatable, Sendable {
    enum TimeBand: String, CaseIterable, Codable, Sendable {
        case morning, afternoon, night

        var title: String {
            switch self {
            case .morning: "Mañana"
            case .afternoon: "Tarde"
            case .night: "Noche"
            }
        }

        init(hour: Int) {
            switch hour {
            case 6..<12: self = .morning
            case 12..<18: self = .afternoon
            default: self = .night
            }
        }
    }

    struct Category: Codable, Equatable, Identifiable, Sendable {
        var id: String { name }
        let name: String
        let share: Double
    }

    struct Month: Codable, Equatable, Identifiable, Sendable {
        var id: Date { start }
        let start: Date
        let count: Int
    }

    static let bogota = TimeZone(identifier: "America/Bogota") ?? TimeZone(secondsFromGMT: -18_000) ?? .gmt

    let updatedAt: Date
    let completed: Int
    let abandoned: Int
    let uniquePlaces: Int
    let categories: [Category]
    let activity: [TimeBand: Int]
    let months: [Month]
    let distanceKilometers: Double?

    var completionRate: Double? {
        let total = completed + abandoned
        return total == 0 ? nil : Double(completed) / Double(total)
    }

    var busiestBands: [TimeBand] {
        guard let maximum = activity.values.max(), maximum > 0 else { return [] }
        return TimeBand.allCases.filter { activity[$0] == maximum }
    }

    static func calculate(completions: [QuestStatisticsCompletion], abandoned: Int, now: Date) -> Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = bogota
        let currentMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let monthStarts = (-5...0).compactMap {
            calendar.date(byAdding: .month, value: $0, to: currentMonth)
        }

        let places = Set(completions.compactMap { $0.quest?.place?.id })
        let categoryNames = completions.compactMap { completion -> String? in
            guard let category = completion.quest?.place?.category?
                .trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                !category.isEmpty else { return nil }
            return category
        }
        let categoryCounts = Dictionary(grouping: categoryNames, by: { $0 }).mapValues(\.count)
        let categorizedCount = categoryNames.count
        let activity = Dictionary(grouping: completions.compactMap { row in
            row.completedAt.map { TimeBand(hour: calendar.component(.hour, from: $0)) }
        }, by: { $0 }).mapValues(\.count)

        let categories = categoryCounts.sorted {
            $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value
        }.prefix(3).map {
            Category(name: $0.key, share: Double($0.value) / Double(categorizedCount))
        }

        return Self(
            updatedAt: now,
            completed: completions.count,
            abandoned: abandoned,
            uniquePlaces: places.count,
            categories: categories,
            activity: activity,
            months: monthStarts.map { month in
                let count = completions.filter { completion in
                    guard let date = completion.completedAt, date >= month, date <= now else { return false }
                    return calendar.dateInterval(of: .month, for: date)?.start == month
                }.count
                return Month(start: month, count: count)
            },
            distanceKilometers: distance(for: completions)
        )
    }

    private static func distance(for completions: [QuestStatisticsCompletion]) -> Double? {
        var total: Double?
        var previous: Coordinates?
        for completion in completions {
            let current = completion.completedAt == nil ? nil : completion.quest?.place.flatMap(Coordinates.init)
            if let previous, let current {
                total = (total ?? 0) + previous.kilometers(to: current)
            }
            previous = current
        }
        return total
    }

    private struct Coordinates {
        let latitude: Double
        let longitude: Double

        init?(_ place: QuestStatisticsCompletion.Place) {
            guard let latitude = place.latitude, (-90...90).contains(latitude),
                  let longitude = place.longitude, (-180...180).contains(longitude) else { return nil }
            self.latitude = latitude * .pi / 180
            self.longitude = longitude * .pi / 180
        }

        func kilometers(to other: Self) -> Double {
            let halfLatitude = (other.latitude - latitude) / 2
            let halfLongitude = (other.longitude - longitude) / 2
            let a = pow(sin(halfLatitude), 2) + cos(latitude) * cos(other.latitude) * pow(sin(halfLongitude), 2)
            return 6_371 * 2 * asin(sqrt(min(1, max(0, a))))
        }
    }
}
