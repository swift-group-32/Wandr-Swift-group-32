import Foundation
import Supabase


class ActiveQuestService {

    // true  = mock data
    // false = calls Supabase
    let useMockData = false

    func fetchActiveQuest() async throws -> ActiveQuestDTO? {
        if useMockData {
            return ActiveQuestDTO.mock
        }

        try await signInTestUserIfNeeded()
        let userId = try await supabase.auth.session.user.id


        let response = try await supabase
            .from("quest_completions")
            .select("""
                id, quest_id, status,
                quest:quests(
                    title,
                    place:places(name, address, latitude, longitude),
                    objectives:quest_objectives(id, title, requires_photo, order_index)
                ),
                checked:quest_objective_completions(objective_id)
                """)
            .eq("user_id", value: userId)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let results = try decoder.decode([ActiveQuestDTO].self, from: response.data)

        return results.first
    }
}
