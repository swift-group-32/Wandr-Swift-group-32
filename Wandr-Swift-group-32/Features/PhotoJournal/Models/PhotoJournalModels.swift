//
//  PhotoJournalModels.swift
//  Wandr-Swift-group-32
//
//  Sprint 4 - Catalina Villacris
//  BQ (type 2): How many of my completed quests have photo proof,
//  and which categories have I documented the most?
//

import Foundation

// MARK: - Rows decoded from Supabase

// The project uses MainActor as the default isolation. These types are
// `nonisolated` so they can be decoded and processed on background threads.

/// One completed quest of the logged-in user, with the photos taken as proof.
nonisolated struct JournalCompletionRow: Decodable, Sendable {
    let id: String
    let questId: String
    let completedAt: Date?
    let quest: JournalQuestInfo?
    let proofs: [JournalProofRow]
}

nonisolated struct JournalQuestInfo: Decodable, Sendable {
    let title: String
    let place: JournalPlaceInfo?
}

nonisolated struct JournalPlaceInfo: Decodable, Sendable {
    let name: String?
    let category: String?
}

/// One checked objective. `photoUrl` is the storage path saved by
/// `complete_objective(p_photo_url)`; it is nil when the step had no photo.
nonisolated struct JournalProofRow: Decodable, Sendable {
    let objectiveId: String
    let photoUrl: String?
}

// MARK: - Report shown in the app (and saved on the phone)

/// One photo shown in the journal grid.
nonisolated struct JournalPhoto: Codable, Sendable, Identifiable, Hashable {
    /// Storage path inside the `quest-photos` bucket. It is also the cache key.
    let path: String
    let questTitle: String
    let placeName: String
    let category: String
    let takenAt: Date?

    var id: String { path }

    /// Cache keys: the grid and the detail keep different sizes.
    var thumbnailKey: String { "journal-thumb|\(path)" }
    var fullKey: String { "journal-full|\(path)" }
}

/// How many documented quests a category has.
nonisolated struct DocumentedCategory: Codable, Sendable, Identifiable, Hashable {
    let category: String
    let documentedQuests: Int
    let completedQuests: Int

    var id: String { category }

    /// Share of the completed quests of this category that have a photo.
    var coverage: Double {
        completedQuests == 0 ? 0 : Double(documentedQuests) / Double(completedQuests)
    }
}

nonisolated struct PhotoJournalReport: Codable, Sendable, Equatable {
    let generatedAt: Date
    let completedQuests: Int
    let documentedQuests: Int
    let totalPhotos: Int
    /// Sorted from most to least documented.
    let categories: [DocumentedCategory]
    /// Newest first.
    let photos: [JournalPhoto]

    /// Percentage (0-100) of completed quests with at least one photo.
    var documentedPercentage: Int {
        completedQuests == 0 ? 0 : Int((Double(documentedQuests) / Double(completedQuests) * 100).rounded())
    }

    var topCategory: DocumentedCategory? {
        categories.first { $0.documentedQuests > 0 }
    }

    static func == (lhs: PhotoJournalReport, rhs: PhotoJournalReport) -> Bool {
        lhs.generatedAt == rhs.generatedAt && lhs.photos == rhs.photos && lhs.categories == rhs.categories
    }
}
