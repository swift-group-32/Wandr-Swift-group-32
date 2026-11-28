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

        let params = AboutYouParams(
            p_age_range: info.age_range,
            p_occupation: info.occupation,
            p_notifications_enabled: info.notifications_enabled
        )
        try await supabase.rpc("update_about_you", params: params).execute()
    }
}

nonisolated struct AboutYouParams: Encodable {
    let p_age_range: String?
    let p_occupation: String?
    let p_notifications_enabled: Bool?
}

