import Foundation

struct HistoryRecommendationStrategy: RecommendationStrategy {

    func recommend(from quests: [Quest]) -> [Quest] {

        // Categories from quests the user has already completed
        let completedCategories = Set(
            quests
                .filter { $0.isCompleted }
                .map { $0.category }
        )

        // Do not recommend quests already completed.
        // Score each remaining quest based on:
        // 1. Similarity with the user's history
        // 2. Whether the quest is saved
        // 3. Place rating
        return quests
            .filter { !$0.isCompleted }
            .sorted { quest1, quest2 in

                let score1 = recommendationScore(
                    for: quest1,
                    completedCategories: completedCategories
                )

                let score2 = recommendationScore(
                    for: quest2,
                    completedCategories: completedCategories
                )

                if score1 != score2 {
                    return score1 > score2
                }

                return quest1.rating > quest2.rating
            }
    }

    private func recommendationScore(
        for quest: Quest,
        completedCategories: Set<String>
    ) -> Double {

        var score = 0.0

        // Quests related to the user's history
        // receive a strong recommendation boost.
        if completedCategories.contains(quest.category) {
            score += 10.0
        }

        // Saved quests receive an additional boost.
        if quest.isSaved {
            score += 3.0
        }

        // General place rating contributes to the score.
        score += quest.rating

        return score
    }
}
