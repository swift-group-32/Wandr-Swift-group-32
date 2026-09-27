import Testing
import Foundation
@testable import Wandr_Swift_group_32


struct ProfileIntegrationTests {

    func makeProfile(weeks: [Int]) -> StreakDTO {
        var history: [WeekData] = []
        for i in 0..<weeks.count {
            history.append(WeekData(weekId: "W\(i + 1)", quests: weeks[i]))
        }

        return StreakDTO(
            userId: "test",
            stats: UserStats(questsCompleted: 10, points: 100),
            streak: StreakInfo(
                currentStreak: 3,
                thisWeek: [true, false, false, false, false, false, false],
                weeklyHistory: history
            ),
            achievements: []
        )
    }

        @Test func decodesBackendJSON() throws {
        let json = """
        {
          "userId": "123",
          "stats": { "questsCompleted": 47, "points": 850 },
          "streak": {
            "currentStreak": 14,
            "thisWeek": [true, true, true, true, true, true, false],
            "weeklyHistory": [
              { "weekId": "W1", "quests": 2 },
              { "weekId": "W2", "quests": 5 }
            ]
          },
          "achievements": [
            { "id": "1", "name": "First Foot", "unlocked": true }
          ]
        }
        """

        let data = json.data(using: .utf8)!
        let profile = try JSONDecoder().decode(StreakDTO.self, from: data)

        #expect(profile.streak.currentStreak == 14)
        #expect(profile.stats.points == 850)
        #expect(profile.streak.thisWeek.count == 7)
        #expect(profile.streak.weeklyHistory.count == 2)
        #expect(profile.achievements.first?.name == "First Foot")
    }

    @Test @MainActor func loadsStreakThroughService() async {
        let viewModel = ProfileViewModel()
        await viewModel.loadStreak(userId: "123")

        #expect(viewModel.profile != nil)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test @MainActor func bq4ShowsImprovement() {
        let viewModel = ProfileViewModel()
        viewModel.profile = makeProfile(weeks: [2, 5])

        #expect(viewModel.comparisonMessage.contains("3 more quests"))
    }

    @Test @MainActor func bq4ShowsDecrease() {
        let viewModel = ProfileViewModel()
        viewModel.profile = makeProfile(weeks: [5, 2])

        #expect(viewModel.comparisonMessage.contains("3 fewer quests"))
    }

    @Test @MainActor func bq4ShowsSamePace() {
        let viewModel = ProfileViewModel()
        viewModel.profile = makeProfile(weeks: [4, 4])

        #expect(viewModel.comparisonMessage.contains("Same as last week"))
    }

    @Test @MainActor func bq4NeedsAtLeastTwoWeeks() {
        let viewModel = ProfileViewModel()
        viewModel.profile = makeProfile(weeks: [3])

        #expect(viewModel.comparisonMessage.contains("Not enough weeks"))
    }
}
