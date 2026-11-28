import Foundation
import Supabase

nonisolated struct LowUseCategory: Codable, Equatable, Identifiable, Sendable {
    struct Week: Codable, Equatable, Identifiable, Sendable {
        let weekStart: String
        let starts: Int

        var id: String { weekStart }
    }

    let tagId: String
    let tagName: String
    let totalStarts: Int
    let averagePerWeek: Double
    let weeklyBreakdown: [Week]

    var id: String { tagId }
}

nonisolated struct LowUseCategoriesReport: Codable, Equatable, Sendable {
    let categories: [LowUseCategory]
    let updatedAt: Date
}

enum LowUseCategoriesError: Error {
    case accessDenied
}

@MainActor
protocol LowUseCategoriesServing {
    var currentAccount: UUID? { get }
    func fetch(for account: UUID) async throws -> [LowUseCategory]
}

struct LowUseCategoriesService: LowUseCategoriesServing {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    var currentAccount: UUID? { client.auth.currentSession?.user.id }

    func fetch(for account: UUID) async throws -> [LowUseCategory] {
        do {
            guard try await client.auth.session.user.id == account else {
                throw LowUseCategoriesError.accessDenied
            }
            let response = try await client.rpc("get_low_use_categories").execute()
            return try Self.decode(response.data)
        } catch let error as PostgrestError where ["42501", "PGRST301", "PGRST302", "PGRST303"].contains(error.code ?? "") {
            throw LowUseCategoriesError.accessDenied
        }
    }

    nonisolated static func decode(_ data: Data) throws -> [LowUseCategory] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([LowUseCategory].self, from: data)
    }
}
