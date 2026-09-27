import Foundation
internal import Combine

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


    var comparisonMessage: String {
        guard let history = profile?.streak.weeklyHistory, history.count >= 2 else {
            return "Not enough weeks yet to compare. Keep going!"
        }

        let thisWeek = history[history.count - 1].quests
        let lastWeek = history[history.count - 2].quests
        let difference = thisWeek - lastWeek

        if difference > 0 {
            return "You're improving! \(difference) more quests than last week"
        } else if difference < 0 {
            return "\(-difference) fewer quests than last week. You can do it!"
        } else {
            return "Same as last week. Keep the pace!"
        }
    }
}
