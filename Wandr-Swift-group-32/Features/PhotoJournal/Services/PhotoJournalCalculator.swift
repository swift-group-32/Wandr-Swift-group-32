//
//  PhotoJournalCalculator.swift
//  Wandr-Swift-group-32
//
//  Pure functions: no UI, no network. It runs on a background thread
//  (see PhotoJournalViewModel) and is easy to unit test.
//

import Foundation

nonisolated enum PhotoJournalCalculator {

    static let uncategorized = "Other"

    static func makeReport(from rows: [JournalCompletionRow], now: Date = Date()) -> PhotoJournalReport {
        // Single pass over the rows: O(n + photos).
        var completedByCategory: [String: Int] = [:]
        var documentedByCategory: [String: Int] = [:]
        var photos: [JournalPhoto] = []
        var seenPaths = Set<String>()
        var documentedQuests = 0

        for row in rows {
            let category = normalizedCategory(row.quest?.place?.category)
            completedByCategory[category, default: 0] += 1

            let paths = row.proofs.compactMap { proof -> String? in
                guard let path = proof.photoUrl?.trimmingCharacters(in: .whitespaces), !path.isEmpty else {
                    return nil
                }
                return path
            }
            guard !paths.isEmpty else { continue }

            documentedQuests += 1
            documentedByCategory[category, default: 0] += 1

            for path in paths where seenPaths.insert(path).inserted {
                photos.append(JournalPhoto(
                    path: path,
                    questTitle: row.quest?.title ?? "Quest",
                    placeName: row.quest?.place?.name ?? "",
                    category: category,
                    takenAt: row.completedAt
                ))
            }
        }

        let categories = completedByCategory.map { category, completed in
            DocumentedCategory(
                category: category,
                documentedQuests: documentedByCategory[category] ?? 0,
                completedQuests: completed
            )
        }
        .sorted {
            if $0.documentedQuests != $1.documentedQuests { return $0.documentedQuests > $1.documentedQuests }
            if $0.completedQuests != $1.completedQuests { return $0.completedQuests > $1.completedQuests }
            return $0.category < $1.category
        }

        photos.sort { ($0.takenAt ?? .distantPast) > ($1.takenAt ?? .distantPast) }

        return PhotoJournalReport(
            generatedAt: now,
            completedQuests: rows.count,
            documentedQuests: documentedQuests,
            totalPhotos: photos.count,
            categories: categories,
            photos: photos
        )
    }

    static func normalizedCategory(_ raw: String?) -> String {
        guard let raw = raw?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return uncategorized }
        return raw.prefix(1).uppercased() + raw.dropFirst().lowercased()
    }
}
