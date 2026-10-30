import Foundation
import Supabase


class ActivityInsightsRepository {

    func fetchProfiles() async throws -> [UserProfileRow] {
        try await requireSession()
        return try await supabase.rpc("bq9_user_profiles").execute().value
    }

    func fetchLastOpens() async throws -> [UserLastOpenRow] {
        try await requireSession()
        return try await supabase.rpc("bq9_user_last_open").execute().value
    }

    func fetchQuestHistory() async throws -> [UserQuestRow] {
        try await requireSession()
        return try await supabase.rpc("bq9_user_quest_history").execute().value
    }
}
