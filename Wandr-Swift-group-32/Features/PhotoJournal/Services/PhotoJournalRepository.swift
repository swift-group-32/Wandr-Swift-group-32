

import Foundation
import Supabase

nonisolated protocol PhotoJournalServing: Sendable {
    func currentUserId() async throws -> String
    func fetchCompletedQuests() async throws -> [JournalCompletionRow]
    func signedURLs(for paths: [String]) async throws -> [String: URL]
}

nonisolated final class PhotoJournalRepository: PhotoJournalServing {

    static let bucket = "quest-photos"
    
    private let signedURLLifetime = 60 * 60

    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    func currentUserId() async throws -> String {
        if let saved = client.auth.currentSession {
            return saved.user.id.uuidString.lowercased()
        }
        return try await client.auth.session.user.id.uuidString.lowercased()
    }

    
    func fetchCompletedQuests() async throws -> [JournalCompletionRow] {
        let userId = try await currentUserId()

        let response = try await client
            .from("quest_completions")
            .select("""
                id, quest_id, completed_at,
                quest:quests(title, place:places(name, category)),
                proofs:quest_objective_completions(objective_id, photo_url:proof_photo)
                """)
            .eq("user_id", value: userId)
            .eq("status", value: "completed")
            .order("completed_at", ascending: false)
            .execute()

        let data = response.data
        return try await Task.detached(priority: .userInitiated) {
            try Self.decoder.decode([JournalCompletionRow].self, from: data)
        }.value
    }

    func signedURLs(for paths: [String]) async throws -> [String: URL] {
        guard !paths.isEmpty else { return [:] }
        let bucket = client.storage.from(Self.bucket)
        let lifetime = signedURLLifetime

        return await withTaskGroup(of: (String, URL?).self) { group in
            for path in paths {
                group.addTask {
                    let url = try? await bucket.createSignedURL(path: path, expiresIn: lifetime)
                    return (path, url)
                }
            }
            var result: [String: URL] = [:]
            for await (path, url) in group {
                if let url { result[path] = url }
            }
            return result
        }
    }

    

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = SupabaseDate.parse(text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(text)")
            }
            return date
        }
        return decoder
    }()
}


nonisolated enum SupabaseDate {
    nonisolated(unsafe) private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    nonisolated(unsafe) private static let dateOnly: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    private static let lock = NSLock()

    static func parse(_ text: String) -> Date? {
        var clean = text
        if let dot = clean.firstIndex(of: ".") {
            let afterDot = clean[clean.index(after: dot)...]
            let end = afterDot.firstIndex { !$0.isNumber } ?? clean.endIndex
            clean.removeSubrange(dot..<end)
        }
        if !clean.contains("Z") && !clean.contains("+") && clean.filter({ $0 == "-" }).count <= 2 && clean.contains("T") {
            clean += "Z"
        }
        lock.lock()
        defer { lock.unlock() }
        return formatter.date(from: clean) ?? dateOnly.date(from: text)
    }
}
