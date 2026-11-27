//
//  ReengagementService.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 26/11/26.
//

import Foundation
import Supabase

protocol ReengagementInsightsServing {
    func fetchInsights() async throws -> ReengagementInsightsReport
}

final class ReengagementInsightsService: ReengagementInsightsServing {

    private let cliente: SupabaseClient
    private let cache: ReengagementInsightsCache

    init(
        cliente: SupabaseClient = SupabaseManager.shared.client,
        cache: ReengagementInsightsCache = ReengagementInsightsCache.shared
    ) {
        self.cliente = cliente
        self.cache = cache
    }

    private struct ReengagementResponse: Decodable, Sendable {
        let user_id: UUID
        let user_name: String
        let activity_drop_percentage: Double
        let preferred_category: String

        let recommended_quest_id: UUID
        let recommended_quest_title: String
        let recommended_quest_description: String
        let sponsor_name: String

        let sponsored_quest_category: String
        let matches_preferred_category: Bool
        let matches_previous_category: Bool
        let reengagement_likelihood: Double
    }

    func fetchInsights() async throws -> ReengagementInsightsReport {

        let respuesta = try await cliente
            .rpc("get_reengagement_insights")
            .execute()

        let datos = respuesta.data

        let respuestas = try await Task.detached(
            priority: .utility
        ) {
            let decoder = JSONDecoder()

            return try decoder.decode(
                [ReengagementResponse].self,
                from: datos
            )
        }.value

        let fechaGeneracion = Date()

        let recomendaciones = respuestas.map { respuesta in
            ReengagementRecommendation(
                userId: respuesta.user_id,
                userName: respuesta.user_name,
                activityDropPercentage: respuesta.activity_drop_percentage,
                preferredCategory: respuesta.preferred_category,
                recommendedQuestId: respuesta.recommended_quest_id,
                recommendedQuestTitle: respuesta.recommended_quest_title,
                recommendedQuestDescription: respuesta.recommended_quest_description,
                sponsorName: respuesta.sponsor_name,
                sponsoredQuestCategory: respuesta.sponsored_quest_category,
                matchesPreferredCategory: respuesta.matches_preferred_category,
                matchesPreviousCategory: respuesta.matches_previous_category,
                reengagementLikelihood: respuesta.reengagement_likelihood,
                generatedAt: fechaGeneracion
            )
        }

        cache.saveAll(recomendaciones)

        return ReengagementInsightsReport(
            generatedAt: fechaGeneracion,
            recommendations: recomendaciones
        )
    }
}
