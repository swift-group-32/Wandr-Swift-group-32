//
//  SponsoredQuestRepository.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 29/10/26.
//

import Foundation
import Supabase

protocol SponsoredQuestRepository {
    func fetchCurrentUserActivity() async throws -> ActiveUser?
}

final class SupabaseSponsoredQuestRepository: SponsoredQuestRepository {

    private let supabase = SupabaseManager.shared.client

    func fetchCurrentUserActivity() async throws -> ActiveUser? {

        let userId = try await supabase.auth.session.user.id

        async let completions = fetchMonthlyCompletions(userId: userId)
        async let user = fetchUser(userId: userId)
        async let sponsoredAttempts = fetchSponsoredQuestAttempts(
            userId: userId
        )
        async let sponsoredQuest = fetchActiveSponsoredQuest()

        let (
            monthlyCompletions,
            userProfile,
            hasTriedSponsoredQuest,
            availableSponsoredQuest
        ) = try await (
            completions,
            user,
            sponsoredAttempts,
            sponsoredQuest
        )

        guard monthlyCompletions.count >= 5 else {
            return nil
        }

        return ActiveUser(
            userId: userId.uuidString,
            name: userProfile.name,
            completedQuests: monthlyCompletions.count,
            hasTriedSponsoredQuest: hasTriedSponsoredQuest,
            sponsoredQuest: availableSponsoredQuest
        )
    }

    private func fetchMonthlyCompletions(
        userId: UUID
    ) async throws -> [Completion] {

        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: now
            )
        ) else {
            return []
        }

        let formatter = ISO8601DateFormatter()

        let response = try await supabase
            .from("quest_completions")
            .select("user_id, completed_at, status")
            .eq("user_id", value: userId)
            .eq("status", value: "completed")
            .gte(
                "completed_at",
                value: formatter.string(from: startOfMonth)
            )
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(
            [Completion].self,
            from: response.data
        )
    }

    private func fetchUser(
        userId: UUID
    ) async throws -> UserInfo {

        let response = try await supabase
            .from("users")
            .select("id, name")
            .eq("id", value: userId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(
            UserInfo.self,
            from: response.data
        )
    }

    private func fetchSponsoredQuestAttempts(
        userId: UUID
    ) async throws -> Bool {

        let response = try await supabase
            .from("sponsored_quest_attempts")
            .select("id")
            .eq("user_id", value: userId)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()

        let attempts = try decoder.decode(
            [SponsoredQuestAttempt].self,
            from: response.data
        )

        return !attempts.isEmpty
    }

    private func fetchActiveSponsoredQuest()
    async throws -> SponsoredQuest? {

        let response = try await supabase
            .from("sponsored_quests")
            .select("""
                id,
                quest_id,
                sponsor_name,
                description
            """)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let sponsoredQuests = try decoder.decode(
            [SponsoredQuestResponse].self,
            from: response.data
        )

        guard let sponsoredQuest = sponsoredQuests.first else {
            return nil
        }

        let questResponse = try await supabase
            .from("quests")
            .select("""
                title,
                description,
                estimated_duration,
                places (
                    name,
                    category,
                    average_rating
                )
            """)
            .eq(
                "id",
                value: sponsoredQuest.questId
            )
            .single()
            .execute()

        let quest = try decoder.decode(
            QuestResponse.self,
            from: questResponse.data
        )

        return SponsoredQuest(
            id: sponsoredQuest.id,
            title: quest.title,
            description: quest.description
                ?? sponsoredQuest.description
                ?? "",
            sponsorName: sponsoredQuest.sponsorName,
            duration: quest.estimatedDuration ?? 0,
            rating: quest.places?.averageRating ?? 0,
            category: quest.places?.category ?? "other"
        )
    }
}

private struct Completion: Decodable {
    let userId: String
    let completedAt: String?
    let status: String
}

private struct UserInfo: Decodable {
    let id: UUID
    let name: String
}

private struct SponsoredQuestAttempt: Decodable {
    let id: UUID
}

private struct SponsoredQuestResponse: Decodable {
    let id: UUID
    let questId: UUID
    let sponsorName: String
    let description: String?
}

private struct QuestResponse: Decodable {
    let title: String
    let description: String?
    let estimatedDuration: Int?
    let places: QuestPlaceResponse?
}

private struct QuestPlaceResponse: Decodable {
    let name: String?
    let category: String?
    let averageRating: Double?
}
