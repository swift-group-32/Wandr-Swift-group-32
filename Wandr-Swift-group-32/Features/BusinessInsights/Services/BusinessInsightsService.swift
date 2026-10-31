import Foundation
import Supabase

@MainActor
protocol BusinessInsightsServing {
    var currentAccountID: String? { get }
    func hasBusinessAccess() async throws -> Bool
    func activate(code: String) async throws
    func fetchReport() async throws -> CategoryEngagementReport
}

enum BusinessInsightsError: Error, Equatable {
    case invalidCode, accessDenied, signInRequired, offline, unavailable
}

@MainActor
struct BusinessInsightsService: BusinessInsightsServing {
    private let client: SupabaseClient

    init(client: SupabaseClient? = nil) {
        self.client = client ?? supabase
    }

    var currentAccountID: String? {
        client.auth.currentSession?.user.id.uuidString.lowercased()
    }

    func hasBusinessAccess() async throws -> Bool {
        try await request {
            let userID = try await client.auth.session.user.id
            struct Access: Decodable { let is_business: Bool }
            let access: Access = try await client.from("users")
                .select("is_business").eq("id", value: userID)
                .single().execute().value
            return access.is_business
        }
    }

    func activate(code: String) async throws {
        try await request {
            _ = try await client.auth.session
            let activated: Bool = try await client.rpc("activate_business_access", params: ["p_code": code])
                .execute().value
            guard activated else { throw BusinessInsightsError.invalidCode }
        }
    }

    func fetchReport() async throws -> CategoryEngagementReport {
        try await request {
            _ = try await client.auth.session
            let response = try await client.rpc("get_category_engagement").execute()
            let data = response.data
            // Decode a Sendable value away from the main actor; UI and SwiftData stay on it.
            return try await Task.detached(priority: .utility) {
                try CategoryEngagementReport.decode(data)
            }.value
        }
    }

    private func request<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as PostgrestError {
            switch error.code {
            case "22023": throw BusinessInsightsError.invalidCode
            case "42501": throw BusinessInsightsError.accessDenied
            case "PGRST301", "PGRST303": throw BusinessInsightsError.signInRequired
            default: throw BusinessInsightsError.unavailable
            }
        } catch is AuthError {
            throw BusinessInsightsError.signInRequired
        } catch let error as URLError where error.code != .cancelled {
            throw BusinessInsightsError.offline
        }
    }
}
