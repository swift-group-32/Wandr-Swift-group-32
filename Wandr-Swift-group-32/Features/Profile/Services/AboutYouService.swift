import Foundation
import Supabase


class AboutYouService {

    func fetch() async throws -> AboutYouDTO {
        try await requireSession()
        let userId = try await supabase.auth.session.user.id

        return try await supabase
            .from("users")
            .select("age_range, occupation, notifications_enabled")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    func save(_ info: AboutYouDTO) async throws {
        try await requireSession()
        let userId = try await supabase.auth.session.user.id

        try await supabase
            .from("users")
            .update(info)
            .eq("id", value: userId)
            .execute()
    }
}
