import Foundation
import Combine
import CoreLocation

@MainActor
class ProfileViewModel: ObservableObject {

    @Published var profile: StreakDTO? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let service = StreakService()

    func loadStreak(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await service.fetchStreak(userId: userId)
        } catch {
            errorMessage = "Could not load your streak. Check your connection."
        }

        isLoading = false
    }

    var weekDifference: Int? {
        guard let history = profile?.streak.weeklyHistory, history.count >= 2 else { return nil }
        return history[history.count - 1].quests - history[history.count - 2].quests
    }

    var comparisonMessage: String {
        guard let difference = weekDifference else {
            return "Not enough weeks yet to compare. Keep going!"
        }
        let amount = abs(difference)
        let word = amount == 1 ? "quest" : "quests"

        if difference > 0 {
            return "You're improving! \(amount) more \(word) than last week!"
        } else if difference < 0 {
            return "\(amount) fewer \(word) than last week. You can catch up!"
        } else {
            return "Same as last week. Keep the pace!"
        }
    }

    func weekLabel(_ week: WeekData) -> String {
        if week.id == profile?.streak.weeklyHistory.last?.id {
            return "This week"
        }
        return week.weekId
    }


    let xpPerLevel = 200

    var nextLevel: Int {
        (profile?.stats.level ?? 1) + 1
    }

    var xpIntoLevel: Int {
        (profile?.stats.points ?? 0) % xpPerLevel
    }

    var xpToGo: Int {
        xpPerLevel - xpIntoLevel
    }

    var levelProgress: Double {
        Double(xpIntoLevel) / Double(xpPerLevel)
    }


    var activeDaysCount: Int {
        profile?.streak.thisWeek.filter { $0 }.count ?? 0
    }

    var todayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }


    var unlockedCount: Int {
        profile?.achievements.filter { $0.unlocked }.count ?? 0
    }

    var totalBadges: Int {
        profile?.achievements.count ?? 0
    }

    func badgeSubtitle(_ achievement: Achievement) -> String {
        if achievement.unlocked {
            return "Unlocked \(achievement.earnedOn ?? "")"
        }
        return achievement.description ?? "Keep exploring to unlock it"
    }
}
