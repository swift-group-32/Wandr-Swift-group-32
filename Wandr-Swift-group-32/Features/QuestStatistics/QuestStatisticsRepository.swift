import Foundation
import Supabase
import os

nonisolated struct QuestStatisticsRepository: Sendable {
    private static let signposter = OSSignposter(subsystem: "Wandr", category: .pointsOfInterest)
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    var currentAccount: UUID? { client.auth.currentSession?.user.id }

    func fetch(for account: UUID) async throws -> QuestStatistics {
        guard try await client.auth.session.user.id == account else { throw CancellationError() }
        async let completed = fetchCompleted(for: account)
        async let abandoned = fetchAbandonedCount(for: account)
        let (rows, count) = try await (completed, abandoned)
        try Task.checkCancellation()

        let calculation = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let interval = Self.signposter.beginInterval("Quest statistics aggregation")
            defer { Self.signposter.endInterval("Quest statistics aggregation", interval) }
            return QuestStatistics.calculate(completions: rows, abandoned: count, now: .now)
        }
        return try await withTaskCancellationHandler {
            try await calculation.value
        } onCancel: {
            calculation.cancel()
        }
    }

    private func fetchCompleted(for account: UUID) async throws -> [QuestStatisticsCompletion] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = PhotoJournalRepository.decoder.dateDecodingStrategy
        let pageSize = 200
        var rows: [QuestStatisticsCompletion] = []
        var total: Int?

        repeat {
            try Task.checkCancellation()
            let offset = rows.count
            let response = try await client.from("quest_completions")
                .select("id, completed_at, quest:quests(place:places(id, category, latitude, longitude))",
                        count: offset == 0 ? .exact : nil)
                .eq("user_id", value: account)
                .eq("status", value: "completed")
                .order("completed_at", ascending: true)
                .order("id", ascending: true)
                .range(from: offset, to: offset + pageSize - 1)
                .execute()
            if offset == 0 {
                guard let count = response.count else { throw URLError(.badServerResponse) }
                total = count
            }
            let page = try decoder.decode([QuestStatisticsCompletion].self, from: response.data)
            if page.isEmpty, offset < (total ?? 0) { throw URLError(.badServerResponse) }
            rows.append(contentsOf: page)
        } while rows.count < (total ?? 0)

        return rows
    }

    private func fetchAbandonedCount(for account: UUID) async throws -> Int {
        let response = try await client.from("quest_completions")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: account)
            .eq("status", value: "abandoned")
            .execute()
        guard let count = response.count else { throw URLError(.badServerResponse) }
        return count
    }
}
