import Foundation
import Combine

@MainActor
class DiscoveryViewModel: ObservableObject {

    @Published var quests: [Quest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: QuestRepository
    private let strategy: RecommendationStrategy

    init(
        repository: QuestRepository,
        strategy: RecommendationStrategy
    ) {
        self.repository = repository
        self.strategy = strategy
    }

    func loadRecommendations(
        userId: String,
        savedQuestIds: Set<String> = []
    ) async {

        isLoading = true
        errorMessage = nil

        do {
            var quests = try await repository.getPersonalizedQuests(
                userId: userId
            )

            // Add the local saved state to each quest
            quests = quests.map { quest in
                var updatedQuest = quest
                updatedQuest.isSaved =
                    savedQuestIds.contains(quest.id)

                return updatedQuest
            }

            self.quests = strategy.recommend(
                from: quests
            )

        } catch {
            errorMessage = "Could not load recommendations."
        }

        isLoading = false
    }
}
