import Testing
import Foundation
@testable import Wandr_Swift_group_32

struct RatingReviewTests {
    @MainActor private final class SuccessfulSubmission: ReviewSubmitting {
        var calls = 0
        var submittedNotes: String?
        func submit(_ draft: ReviewDraft, photos: [ReviewPhoto]) async throws -> ReviewSubmissionResult {
            calls += 1
            submittedNotes = draft.notes
            return ReviewSubmissionResult(reviewId: UUID(), xpEarned: 20,
                                          alreadySubmitted: false, featureOnDiscoveryMap: draft.featureOnDiscoveryMap)
        }
    }

    @Test @MainActor func successUsesServerRewardAndCannotResubmit() async {
        let service = SuccessfulSubmission()
        let model = RatingReviewViewModel(context: .preview, service: service)
        model.notes = "  Great discovery  "
        await model.save()
        await model.save()
        #expect(model.didSave)
        #expect(model.submissionResult?.xpEarned == 20)
        #expect(service.calls == 1)
        #expect(service.submittedNotes == "Great discovery")
    }

    @Test func decodesBackendSubmissionResult() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = Data("""
        {"review_id":"10000000-0000-0000-0000-000000000001","xp_earned":0,
         "already_submitted":true,"feature_on_discovery_map":false}
        """.utf8)
        let result = try decoder.decode(ReviewSubmissionResult.self, from: data)
        #expect(result.alreadySubmitted)
        #expect(result.xpEarned == 0)
    }
    @Test @MainActor func submissionFailurePreservesTheReviewForRetry() async {
        let model = RatingReviewViewModel(context: .preview)
        model.notes = "My discovery"
        model.rating = 3
        model.toggleHighlight("Hidden Gem")
        await model.save()
        #expect(!model.didSave)
        #expect(!model.isSubmitting)
        #expect(model.errorMessage != nil)
        #expect(model.notes == "My discovery")
        #expect(model.rating == 3)
        #expect(model.selectedHighlights.contains("Hidden Gem"))
    }

    @Test @MainActor func notesLimitPreservesUnicodeCharacters() {
        let model = RatingReviewViewModel(context: .preview)
        let character = "👨‍👩‍👧‍👦"
        model.notes = String(repeating: character, count: 501)
        #expect(model.notes.unicodeScalars.count <= 500)
        #expect(model.notes == String(repeating: character, count: 500 / character.unicodeScalars.count))
        model.notes = "A shorter note"
        #expect(model.notes == "A shorter note")
    }

    @Test @MainActor func invalidPhotoDoesNotBecomeAnAttachment() {
        let model = RatingReviewViewModel(context: .preview)
        model.addPhoto(Data("not an image".utf8))
        #expect(model.photos.isEmpty)
        #expect(model.errorMessage != nil)
    }

    @Test @MainActor func realQuestDoesNotUseBakerySpecificHighlights() {
        let context = ReviewContext(questId: "concert", title: "Catch a live set",
                                    placeName: "Festival Jazz", address: nil, xpEarned: 80)
        let model = RatingReviewViewModel(context: context)
        #expect(!model.highlights.contains("Must-Try Pan de Bono"))
        #expect(model.context.questId == "concert")
    }
}
