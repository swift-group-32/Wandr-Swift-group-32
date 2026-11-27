import Testing
import Foundation
@testable import Wandr_Swift_group_32

struct PhotoJournalTests {

    private func row(_ id: String, category: String?, photos: [String?], daysAgo: Double = 0) -> JournalCompletionRow {
        JournalCompletionRow(
            id: id,
            questId: "q-\(id)",
            completedAt: Date(timeIntervalSince1970: 1_800_000_000 - daysAgo * 86_400),
            quest: JournalQuestInfo(title: "Quest \(id)", place: JournalPlaceInfo(name: "Place \(id)", category: category)),
            proofs: photos.enumerated().map { JournalProofRow(objectiveId: "o\($0.offset)", photoUrl: $0.element) }
        )
    }

    @Test func countsDocumentedQuestsAndRanksCategories() {
        let rows = [
            row("1", category: "food", photos: ["u/1/a.jpg", nil], daysAgo: 3),
            row("2", category: "Food", photos: ["u/2/a.jpg"], daysAgo: 1),
            row("3", category: "culture", photos: [nil]),
            row("4", category: "culture", photos: ["u/4/a.jpg", "u/4/b.jpg"], daysAgo: 2),
            row("5", category: nil, photos: []),
            row("6", category: "sports", photos: ["  "])
        ]

        let report = PhotoJournalCalculator.makeReport(from: rows)

        #expect(report.completedQuests == 6)
        #expect(report.documentedQuests == 3)
        #expect(report.documentedPercentage == 50)
        #expect(report.totalPhotos == 4)
        #expect(report.topCategory?.category == "Food")
        #expect(report.categories.first { $0.category == "Culture" }?.completedQuests == 2)
        #expect(report.categories.first { $0.category == "Other" }?.documentedQuests == 0)
        // Newest first
        #expect(report.photos.first?.path == "u/2/a.jpg")
    }

    @Test func emptyHistoryGivesZeroPercent() {
        let report = PhotoJournalCalculator.makeReport(from: [])
        #expect(report.documentedPercentage == 0)
        #expect(report.topCategory == nil)
        #expect(report.photos.isEmpty)
    }

    @Test func decodesSupabaseResponseWithMicroseconds() throws {
        let json = """
        [{
          "id": "c1", "quest_id": "q1", "completed_at": "2026-10-02T15:23:11.123456+00:00",
          "quest": {"title": "Catch a live set", "place": {"name": "Parque El Country", "category": "music"}},
          "proofs": [{"objective_id": "o1", "photo_url": null},
                     {"objective_id": "o3", "photo_url": "abc/q1/o3.jpg"}]
        }]
        """
        let rows = try PhotoJournalRepository.decoder.decode([JournalCompletionRow].self, from: Data(json.utf8))
        #expect(rows.count == 1)
        #expect(rows[0].proofs.compactMap(\.photoUrl) == ["abc/q1/o3.jpg"])
        #expect(rows[0].completedAt != nil)
    }

    @Test func storageSavesAndLoadsPerUser() {
        let storage = PhotoJournalStorage(directoryName: "PhotoJournalTests-\(UUID().uuidString)")
        let report = PhotoJournalCalculator.makeReport(from: [row("1", category: "food", photos: ["x.jpg"])])

        storage.save(report, userId: "user-a")
        #expect(storage.isFresh(userId: "user-a"))
        #expect(storage.loadFromDisk(userId: "user-a")?.totalPhotos == 1)
        #expect(storage.loadFromDisk(userId: "user-b") == nil)

        storage.clearAll()
        #expect(storage.loadFromDisk(userId: "user-a") == nil)
    }
}
