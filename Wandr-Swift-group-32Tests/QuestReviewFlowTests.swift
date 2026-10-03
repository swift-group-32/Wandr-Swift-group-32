import Foundation
import Testing
@testable import Wandr_Swift_group_32

@MainActor
struct QuestReviewFlowTests {
    private final class QuestBackend: ActiveQuestServing {
        let questId = "b1111111-0000-0000-0000-000000000002"
        var started = false
        var completed = false
        var failStart = false
        var finalObjective = true
        var receivedQuestId: String?
        var receivedPhotoPath: String?

        var choice: StartableQuestDTO {
            StartableQuestDTO(id: questId, title: "Dance the night away", estimatedDuration: 60,
                              place: StartableQuestPlace(name: "Andres Carne de Res"))
        }

        func fetchStartableQuests() async throws -> [StartableQuestDTO] { [choice] }
        func fetchActiveQuest() async throws -> ActiveQuestDTO? {
            guard started, !completed else { return nil }
            return ActiveQuestDTO(id: "completion", questId: questId, status: "pending",
                quest: QuestInfo(title: choice.title,
                    place: PlaceInfo(name: choice.place.name, address: nil, latitude: 4.86, longitude: -74.03),
                    objectives: [QuestObjective(id: "objective", title: "Enjoy the music", requiresPhoto: false, orderIndex: 1)]),
                checked: [])
        }
        func startQuest(questId: String) async throws {
            if failStart { throw URLError(.notConnectedToInternet) }
            receivedQuestId = questId
            started = true
        }
        func completeObjective(questId: String, objectiveId: String, photoPath: String?) async throws -> ObjectiveResult {
            receivedPhotoPath = photoPath
            completed = finalObjective
            return ObjectiveResult(questCompleted: finalObjective, xpEarned: finalObjective ? 60 : 0)
        }
        func uploadProofPhoto(questId: String, objectiveId: String, imageData: Data) async throws -> String {
            "user/quest/proof.jpg"
        }
        func abandonQuest(questId: String) async throws {}
    }

    private final class ReviewBackend: ReviewSubmitting {
        var draft: ReviewDraft?
        func submit(_ draft: ReviewDraft, photos: [ReviewPhoto]) async throws -> ReviewSubmissionResult {
            self.draft = draft
            return ReviewSubmissionResult(reviewId: UUID(), xpEarned: 20,
                                          alreadySubmitted: false, featureOnDiscoveryMap: false)
        }
    }

    @Test func selectedQuestFlowsThroughCompletionIntoReviewSubmission() async throws {
        let backend = QuestBackend()
        let model = ActiveQuestViewModel(service: backend)
        await model.loadActiveQuest()
        #expect(model.activeQuest == nil)
        #expect(model.startableQuests.count == 1)
        await model.startQuest(try #require(model.startableQuests.first))
        #expect(backend.receivedQuestId == backend.questId)
        #expect(model.activeQuest?.questId == backend.questId)
        await model.checkObjective(try #require(model.objectives.first))
        let context = try #require(model.reviewContext)
        #expect(context.questId == backend.questId)
        #expect(context.xpEarned == 60)
        #expect(model.activeQuest == nil)
        let reviews = ReviewBackend()
        let review = RatingReviewViewModel(context: context, service: reviews)
        review.rating = 4
        review.notes = "Great music"
        await review.save()
        #expect(review.didSave)
        #expect(reviews.draft?.context.questId == backend.questId)
        #expect(reviews.draft?.rating == 4)
    }

    @Test func failedStartKeepsQuestSelectionAndCanRetry() async {
        let backend = QuestBackend()
        let model = ActiveQuestViewModel(service: backend)
        await model.loadActiveQuest()
        backend.failStart = true
        await model.startQuest(backend.choice)
        #expect(model.actionError != nil)
        #expect(!model.isWorking)
        #expect(model.activeQuest == nil)
        #expect(model.startableQuests.count == 1)
        backend.failStart = false
        await model.startQuest(backend.choice)
        #expect(model.actionError == nil)
        #expect(model.activeQuest != nil)
    }

    @Test func intermediateObjectiveDoesNotOpenReview() async throws {
        let backend = QuestBackend()
        backend.finalObjective = false
        let model = ActiveQuestViewModel(service: backend)
        await model.startQuest(backend.choice)
        await model.checkObjective(try #require(model.objectives.first))
        #expect(model.reviewContext == nil)
    }

    @Test func photoObjectiveCompletionAlsoOpensReview() async throws {
        let backend = QuestBackend()
        let model = ActiveQuestViewModel(service: backend)
        await model.startQuest(backend.choice)
        let objective = QuestObjective(id: "photo", title: "Take a photo", requiresPhoto: true, orderIndex: 1)
        await model.submitPhoto(for: objective, imageData: Data([1, 2, 3]))
        #expect(backend.receivedPhotoPath == "user/quest/proof.jpg")
        #expect(model.reviewContext?.questId == backend.questId)
    }
}
