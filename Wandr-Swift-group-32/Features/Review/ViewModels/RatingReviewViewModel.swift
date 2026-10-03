import Foundation
internal import Combine
import UIKit

@MainActor
final class RatingReviewViewModel: ObservableObject {
    let context: ReviewContext
    var highlights: [String] {
        context.id == ReviewContext.preview.id
            ? ["Cozy Vibes", "Must-Try Pan de Bono", "Hidden Gem", "Friendly Staff", "Great Coffee", "Budget Friendly", "Quiet & Chill"]
            : ["Great Atmosphere", "Hidden Gem", "Friendly People", "Worth the Visit", "Budget Friendly", "Quiet & Chill", "Would Return"]
    }
    let characterLimit = 500
    let photoLimit = 4
    @Published var rating = 5
    @Published var selectedHighlights: Set<String> = []
    @Published var notes = "" {
        didSet {
            if notes.unicodeScalars.count > characterLimit {
                var result = ""
                for character in notes {
                    if result.unicodeScalars.count + character.unicodeScalars.count > characterLimit { break }
                    result.append(character)
                }
                notes = result
            }
        }
    }
    @Published var photos: [ReviewPhoto] = []
    @Published var featureOnDiscoveryMap = false
    @Published var accuracy: ReviewAccuracy = .spotOn
    @Published var isLoadingPhotos = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var didSave = false
    @Published var submissionResult: ReviewSubmissionResult?
    private let service: any ReviewSubmitting

    init(context: ReviewContext, service: (any ReviewSubmitting)? = nil) {
        self.context = context
        self.service = service ?? ReviewService()
    }

    var ratingDescription: String {
        switch rating {
        case 1: "Needs improvement"
        case 2: "Decent discovery"
        case 3: "Good experience"
        case 4: "Great side quest!"
        default: "Exceptional experience"
        }
    }

    func toggleHighlight(_ highlight: String) {
        if selectedHighlights.contains(highlight) { selectedHighlights.remove(highlight) }
        else { selectedHighlights.insert(highlight) }
    }

    func save() async {
        guard !isSubmitting, !isLoadingPhotos, !didSave else { return }
        guard (1...5).contains(rating) else {
            errorMessage = "Choose a rating between one and five stars."
            return
        }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        let draft = ReviewDraft(
            context: context, rating: rating,
            highlights: highlights.filter { selectedHighlights.contains($0) },
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            featureOnDiscoveryMap: featureOnDiscoveryMap, accuracy: accuracy
        )
        do {
            submissionResult = try await service.submit(draft, photos: photos)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addPhoto(_ data: Data) {
        guard photos.count < photoLimit else { return }
        guard let image = UIImage(data: data) else {
            errorMessage = "This photo could not be opened. Please choose another image."
            return
        }
        // Bound local attachments rather than retaining full-resolution library images.
        let scale = min(1, 1600 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let jpeg = resized.jpegData(compressionQuality: 0.8) else {
            errorMessage = "This photo could not be prepared. Please try another image."
            return
        }
        photos.append(ReviewPhoto(data: jpeg))
    }
}
