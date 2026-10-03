//
//  Wandr_Swift_group_32Tests.swift
//  Wandr-Swift-group-32Tests
//
//  Created by Manuela Victoria Ragua on 25/09/26.
//

import Testing
import Foundation
@testable import Wandr_Swift_group_32

struct FailingQuestRepository: QuestRepository {

    func getPersonalizedQuests(userId: String) async throws -> [Quest] {
        throw NSError(
            domain: "TestError",
            code: 1
        )
    }
}

struct Wandr_Swift_group_32Tests {

    @Test
    @MainActor
    func recommendationsLoadSuccessfully() async {

        let repository = MockQuestRepository()
        let strategy = HistoryRecommendationStrategy()

        let viewModel = DiscoveryViewModel(
            repository: repository,
            strategy: strategy
        )

        await viewModel.loadRecommendations(userId: "user-1")

        #expect(!viewModel.quests.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test
    @MainActor
    func completedQuestsAreExcluded() async {

        let repository = MockQuestRepository()
        let strategy = HistoryRecommendationStrategy()

        let viewModel = DiscoveryViewModel(
            repository: repository,
            strategy: strategy
        )

        await viewModel.loadRecommendations(userId: "user-1")

        let completedQuests = viewModel.quests.filter {
            $0.isCompleted
        }

        #expect(completedQuests.isEmpty)
    }

    @Test
    @MainActor
    func historyBasedRecommendationsArePrioritized() async {

        let repository = MockQuestRepository()
        let strategy = HistoryRecommendationStrategy()

        let viewModel = DiscoveryViewModel(
            repository: repository,
            strategy: strategy
        )

        await viewModel.loadRecommendations(userId: "user-1")

        #expect(!viewModel.quests.isEmpty)

        let firstQuest = viewModel.quests[0]

        #expect(firstQuest.category == "Outdoor")
    }

    @Test
    @MainActor
    func recommendationsAreSortedByRating() async {

        let repository = MockQuestRepository()
        let strategy = RatingRecommendationStrategy()

        let viewModel = DiscoveryViewModel(
            repository: repository,
            strategy: strategy
        )

        await viewModel.loadRecommendations(userId: "user-1")

        for index in 0..<(viewModel.quests.count - 1) {
            #expect(
                viewModel.quests[index].rating
                >= viewModel.quests[index + 1].rating
            )
        }
    }

    @Test
    @MainActor
    func errorStateIsHandled() async {

        let repository = FailingQuestRepository()
        let strategy = HistoryRecommendationStrategy()

        let viewModel = DiscoveryViewModel(
            repository: repository,
            strategy: strategy
        )

        await viewModel.loadRecommendations(userId: "user-1")

        #expect(viewModel.quests.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test
    func historyCategoryGetsPriority() {

        let strategy = HistoryRecommendationStrategy()

        let quests = [
            Quest(
                id: "1",
                title: "Completed Outdoor Quest",
                category: "Outdoor",
                description: "Completed quest",
                duration: 30,
                rating: 4.5,
                isCompleted: true,
                isSaved: false
            ),
            Quest(
                id: "2",
                title: "New Outdoor Quest",
                category: "Outdoor",
                description: "Related to user history",
                duration: 30,
                rating: 4.5,
                isCompleted: false,
                isSaved: false
            ),
            Quest(
                id: "3",
                title: "New Food Quest",
                category: "Food",
                description: "Different category",
                duration: 30,
                rating: 4.9,
                isCompleted: false,
                isSaved: false
            )
        ]

        let recommendations = strategy.recommend(
            from: quests
        )

        #expect(recommendations.first?.id == "2")
    }

    @Test
    func savedQuestGetsPriority() {

        let strategy = HistoryRecommendationStrategy()

        let quests = [
            Quest(
                id: "1",
                title: "Completed Outdoor Quest",
                category: "Outdoor",
                description: "Completed quest",
                duration: 30,
                rating: 4.5,
                isCompleted: true,
                isSaved: false
            ),
            Quest(
                id: "2",
                title: "Saved Outdoor Quest",
                category: "Outdoor",
                description: "Saved quest",
                duration: 30,
                rating: 4.5,
                isCompleted: false,
                isSaved: true
            ),
            Quest(
                id: "3",
                title: "Unsaved Outdoor Quest",
                category: "Outdoor",
                description: "Unsaved quest",
                duration: 30,
                rating: 4.5,
                isCompleted: false,
                isSaved: false
            )
        ]

        let recommendations = strategy.recommend(
            from: quests
        )

        #expect(recommendations.first?.id == "2")
    }
    
}
