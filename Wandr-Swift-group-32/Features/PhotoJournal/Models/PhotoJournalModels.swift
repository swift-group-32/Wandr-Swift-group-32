

import Foundation

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

nonisolated struct JournalProofRow: Decodable, Sendable {
    let objectiveId: String
    let photoUrl: String?
}

nonisolated struct JournalPhoto: Codable, Sendable, Identifiable, Hashable {

    let path: String
    let questTitle: String
    let placeName: String
    let category: String
    let takenAt: Date?

    var id: String { path }

    var thumbnailKey: String { "journal-thumb|\(path)" }
    var fullKey: String { "journal-full|\(path)" }
}


nonisolated struct DocumentedCategory: Codable, Sendable, Identifiable, Hashable {
    let category: String
    let documentedQuests: Int
    let completedQuests: Int

    var id: String { category }

    var coverage: Double {
        completedQuests == 0 ? 0 : Double(documentedQuests) / Double(completedQuests)
    }
}

nonisolated struct PhotoJournalReport: Codable, Sendable, Equatable {
    let generatedAt: Date
    let completedQuests: Int
    let documentedQuests: Int
    let totalPhotos: Int
    let categories: [DocumentedCategory]
    
    let photos: [JournalPhoto]

    
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
