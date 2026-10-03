import Foundation
import Supabase

@MainActor
protocol ReviewSubmitting {
    func submit(_ draft: ReviewDraft, photos: [ReviewPhoto]) async throws -> ReviewSubmissionResult
}

@MainActor
struct ReviewService: ReviewSubmitting {
    enum SubmissionError: LocalizedError {
        case preview
        var errorDescription: String? {
            "This is a preview quest. Complete a real quest to submit a review."
        }
    }

    func submit(_ draft: ReviewDraft, photos: [ReviewPhoto]) async throws -> ReviewSubmissionResult {
        guard let questId = UUID(uuidString: draft.context.questId) else { throw SubmissionError.preview }
        try await signInTestUserIfNeeded()
        let userId = try await supabase.auth.session.user.id.uuidString.lowercased()
        // Check before uploading: a retry after a lost success response must not overwrite
        // photos already referenced by an immutable submitted review.
        let existing = try await supabase.from("quest_reviews").select("id")
            .eq("user_id", value: userId).eq("quest_id", value: questId).limit(1).execute()
        struct ExistingReview: Decodable { let id: UUID }
        let hasReview = !(try JSONDecoder().decode([ExistingReview].self, from: existing.data)).isEmpty
        var paths: [String] = []
        if !hasReview {
            for photo in photos {
                let path = "\(userId)/\(questId.uuidString.lowercased())/\(photo.id.uuidString.lowercased()).jpg"
                try await supabase.storage.from("review-photos")
                    .upload(path, data: photo.data, options: FileOptions(contentType: "image/jpeg", upsert: true))
                paths.append(path)
            }
        }
        let parameters = ReviewSubmissionParameters(
            p_quest_id: questId.uuidString.lowercased(), p_rating: draft.rating,
            p_notes: draft.notes, p_highlights: draft.highlights, p_accuracy: draft.accuracy.rawValue,
            p_feature_on_discovery_map: draft.featureOnDiscoveryMap, p_photo_paths: paths
        )
        let response = try await supabase.rpc("submit_quest_review", params: parameters).execute()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ReviewSubmissionResult.self, from: response.data)
    }
}
