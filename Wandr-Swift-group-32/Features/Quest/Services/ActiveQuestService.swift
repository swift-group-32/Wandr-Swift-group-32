import Foundation
import Supabase
import UIKit
import os

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

    /// MO1 measurement switch. true = Sprint 3 code, only to take the "before" numbers.
    static var measureLegacyCompression = false
    
    private static let signposter = OSSignposter(subsystem: "Wandr", category: .pointsOfInterest)

    
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func fetchStartableQuests() async throws -> [StartableQuestDTO] {
        try await requireSession()
        let userId = try await supabase.auth.session.user.id
        
        async let catalogRequest = supabase.from("quests")
            .select("id, title, estimated_duration, place:places(name)")
            .order("title", ascending: true).execute()
        async let completionsRequest = supabase.from("quest_completions")
            .select("quest_id").eq("user_id", value: userId)
            .eq("status", value: "completed").execute()
        let (catalog, completions) = try await (catalogRequest, completionsRequest)

        struct Completion: Decodable { let questId: String }
        let decoder = Self.decoder
        let completed = Set(try decoder.decode([Completion].self, from: completions.data).map(\.questId))
        return try decoder.decode([StartableQuestDTO].self, from: catalog.data)
            .filter { !completed.contains($0.id) }
    }

    func startQuest(questId: String) async throws {
        try await requireSession()
        try await supabase.rpc("start_quest", params: ["p_quest_id": questId]).execute()
    }

    func fetchActiveQuest() async throws -> ActiveQuestDTO? {
        if useMockData {
            return ActiveQuestDTO.mock
        }

        try await requireSession()
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

        let results = try Self.decoder.decode([ActiveQuestDTO].self, from: response.data)

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

        let result = try Self.decoder.decode(ObjectiveResult.self, from: response.data)
        if result.questCompleted { QuestStatisticsStore.shared.invalidate() }
        return result
    }


    func uploadProofPhoto(questId: String, objectiveId: String, imageData: Data) async throws -> String {
        if useMockData { return "mock.jpg" }

        let userId = try await supabase.auth.session.user.id

        let path = "\(userId.uuidString.lowercased())/\(questId)/\(objectiveId).jpg"


        let signpostState = Self.signposter.beginInterval("Compress proof photo")
        let start = ContinuousClock.now
        let jpeg: Data
        if Self.measureLegacyCompression {
            jpeg = UIImage(data: imageData)?.jpegData(compressionQuality: 0.7) ?? imageData
        } else {
            jpeg = await ImageDownsampler.compressForUpload(imageData, maxPixelSize: 1600, quality: 0.7)
        }
        let elapsed = ContinuousClock.now - start
        Self.signposter.endInterval("Compress proof photo", signpostState)
        let ms = Int(elapsed.components.seconds * 1000) + Int(elapsed.components.attoseconds / 1_000_000_000_000_000)
        print("""
            [MO1] \(Self.measureLegacyCompression ? "BEFORE (main thread)" : "AFTER (background thread)") \
            original: \(imageData.count / 1024) KB · processing: \(ms) ms · \
            main thread blocked: \(Self.measureLegacyCompression ? ms : 0) ms · uploaded: \(jpeg.count / 1024) KB
            """)

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
        QuestStatisticsStore.shared.invalidate()
    }
}
