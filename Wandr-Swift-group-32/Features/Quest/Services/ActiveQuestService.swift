import Foundation
import Supabase
import UIKit

@MainActor
protocol ActiveQuestServing {
    func fetchActiveQuest() async throws -> ActiveQuestDTO?
    func fetchStartableQuests() async throws -> [StartableQuestDTO]
    func startQuest(questId: String) async throws
    func completeObjective(questId: String, objectiveId: String, photoPath: String?) async throws -> ObjectiveResult
    func uploadProofPhoto(questId: String, objectiveId: String, imageData: Data) async throws -> String
    func abandonQuest(questId: String) async throws
}

@MainActor
class ActiveQuestService: ActiveQuestServing {

    // true  = mock data
    // false = calls Supabase
    let useMockData = false

    func fetchStartableQuests() async throws -> [StartableQuestDTO] {
        try await signInTestUserIfNeeded()
        let userId = try await supabase.auth.session.user.id
        let catalog = try await supabase.from("quests")
            .select("id, title, estimated_duration, place:places(name)")
            .order("title", ascending: true).execute()
        let completions = try await supabase.from("quest_completions")
            .select("quest_id").eq("user_id", value: userId)
            .eq("status", value: "completed").execute()
        struct Completion: Decodable { let questId: String }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let completed = Set(try decoder.decode([Completion].self, from: completions.data).map(\.questId))
        return try decoder.decode([StartableQuestDTO].self, from: catalog.data)
            .filter { !completed.contains($0.id) }
    }

    func startQuest(questId: String) async throws {
        try await signInTestUserIfNeeded()
        try await supabase.rpc("start_quest", params: ["p_quest_id": questId]).execute()
    }

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
    
    func completeObjective(questId: String, objectiveId: String, photoPath: String?) async throws -> ObjectiveResult {
        if useMockData {
            return ObjectiveResult(questCompleted: false, xpEarned: 0)
        }

        let response = try await supabase
            .rpc("complete_objective", params: [
                "p_quest_id": questId,
                "p_objective_id": objectiveId,
                "p_photo_url": photoPath
            ])
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ObjectiveResult.self, from: response.data)
    }


    func uploadProofPhoto(questId: String, objectiveId: String, imageData: Data) async throws -> String {
        if useMockData { return "mock.jpg" }

        let userId = try await supabase.auth.session.user.id

        let path = "\(userId.uuidString.lowercased())/\(questId)/\(objectiveId).jpg"

        let jpeg = UIImage(data: imageData)?.jpegData(compressionQuality: 0.7) ?? imageData

        try await supabase.storage
            .from("quest-photos")
            .upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: true))

        return path
    }

    func abandonQuest(questId: String) async throws {
        if useMockData { return }

        try await supabase
            .rpc("abandon_quest", params: ["p_quest_id": questId])
            .execute()
    }
}
