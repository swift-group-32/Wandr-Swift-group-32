import Foundation
import Testing
@testable import Wandr_Swift_group_32

struct QuestStatisticsTests {
    @Test func aggregatesCompletedQuestsUsingBogotaTime() throws {
        let rows = try [
            completion("2026-06-01T04:59:00Z", place: "park", category: "park", longitude: 0),
            completion("2026-06-01T05:00:00Z", place: "museum", category: "museum", longitude: 1),
            completion("2026-10-01T10:59:00Z", place: "museum", category: "museum", longitude: 1),
            completion("2026-10-01T11:00:00Z", place: "cafe", category: "restaurant", longitude: 2),
            completion("2026-10-01T17:00:00Z", place: "park", category: "park", longitude: 0),
            completion("2026-10-01T23:00:00Z", place: "park", category: "park", longitude: 0)
        ]
        let report = QuestStatistics.calculate(completions: rows, abandoned: 2, now: try date("2026-11-12T10:00:00Z"))

        #expect(report.completed == 6)
        #expect(report.abandoned == 2)
        #expect(report.completionRate == 0.75)
        #expect(report.uniquePlaces == 3)
        #expect(report.categories.map(\.name) == ["park", "museum", "restaurant"])
        #expect(report.categories.first?.share == 0.5)
        #expect(report.activity == [.morning: 1, .afternoon: 1, .night: 4])
        #expect(report.busiestBands == [.night])
        #expect(report.months.map(\.count) == [1, 0, 0, 0, 4, 0])
        let distance = try #require(report.distanceKilometers)
        #expect(abs(distance - 444.78) < 0.1)
    }

    @Test func missingCoordinatesDoNotConnectNonAdjacentPlaces() throws {
        let rows = try [
            completion("2026-11-01T11:00:00Z", place: "park", category: "park", longitude: 0),
            completion("2026-11-02T17:00:00Z", place: "museum", category: "museum", longitude: nil),
            completion("2026-11-03T11:00:00Z", place: "cafe", category: nil, longitude: 3)
        ]
        let report = QuestStatistics.calculate(completions: rows, abandoned: 0, now: try date("2026-11-12T10:00:00Z"))

        #expect(report.distanceKilometers == nil)
        #expect(report.uniquePlaces == 3)
        #expect(report.categories.map(\.share) == [0.5, 0.5])
    }

    @Test func emptyHistoryAndAnAbandonedOnlyHistoryAreDifferent() throws {
        let now = try date("2026-01-01T05:00:00Z")
        let empty = QuestStatistics.calculate(completions: [], abandoned: 0, now: now)
        let abandoned = QuestStatistics.calculate(completions: [], abandoned: 1, now: now)

        #expect(empty.completionRate == nil)
        #expect(empty.months.map(\.count) == [0, 0, 0, 0, 0, 0])
        #expect(empty.busiestBands.isEmpty)
        #expect(abandoned.completionRate == 0)
    }

    private func completion(_ timestamp: String, place: String, category: String?, longitude: Double?) throws -> QuestStatisticsCompletion {
        QuestStatisticsCompletion(completedAt: try date(timestamp), quest: .init(
            place: .init(id: place, category: category, latitude: 0, longitude: longitude)
        ))
    }

    private func date(_ timestamp: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: timestamp))
    }
}
