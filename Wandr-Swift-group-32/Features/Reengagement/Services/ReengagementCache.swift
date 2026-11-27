//
//  ReengagementCache.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 26/11/26.
//

import Foundation

final class CachedReengagementReport: NSObject {

    let report: ReengagementInsightsReport
    let cachedAt: Date

    init(
        report: ReengagementInsightsReport,
        cachedAt: Date = Date()
    ) {
        self.report = report
        self.cachedAt = cachedAt
    }
}

final class CachedReengagementRecommendation: NSObject {

    let recommendation: ReengagementRecommendation

    init(_ recommendation: ReengagementRecommendation) {
        self.recommendation = recommendation
    }
}

final class ReengagementInsightsCache {

    // Cache compartido entre todas las instancias del ViewModel.
    static let shared = ReengagementInsightsCache()

    private let reportCache =
        NSCache<NSString, CachedReengagementReport>()

    private let recommendationCache =
        NSCache<NSString, CachedReengagementRecommendation>()

    private let reportKey = "reengagement_report"

    // El reporte permanece válido durante 5 minutos.
    private let tiempoValidez: TimeInterval = 300

    private init() {
        reportCache.countLimit = 1
        recommendationCache.countLimit = 100
    }

    // MARK: - Report

    func saveReport(
        _ report: ReengagementInsightsReport
    ) {
        let valor = CachedReengagementReport(
            report: report
        )

        reportCache.setObject(
            valor,
            forKey: reportKey as NSString
        )

        saveAll(report.recommendations)
    }

    func loadReport() -> ReengagementInsightsReport? {

        guard let valor = reportCache.object(
            forKey: reportKey as NSString
        ) else {
            return nil
        }

        // Verificar que el cache todavía sea válido.
        guard Date().timeIntervalSince(valor.cachedAt) < tiempoValidez else {

            reportCache.removeObject(
                forKey: reportKey as NSString
            )

            return nil
        }

        return valor.report
    }

    // MARK: - Recommendations

    func save(
        _ recommendation: ReengagementRecommendation
    ) {
        let clave =
            recommendation.userId.uuidString as NSString

        let valor =
            CachedReengagementRecommendation(
                recommendation
            )

        recommendationCache.setObject(
            valor,
            forKey: clave
        )
    }

    func saveAll(
        _ recommendations: [ReengagementRecommendation]
    ) {
        for recommendation in recommendations {
            save(recommendation)
        }
    }

    func load(
        userId: UUID
    ) -> ReengagementRecommendation? {

        let clave =
            userId.uuidString as NSString

        return recommendationCache.object(
            forKey: clave
        )?.recommendation
    }

    func loadAll(
        for userIds: [UUID]
    ) -> [ReengagementRecommendation] {

        userIds.compactMap {
            load(userId: $0)
        }
    }

    func remove(
        userId: UUID
    ) {
        let clave =
            userId.uuidString as NSString

        recommendationCache.removeObject(
            forKey: clave
        )
    }

    // MARK: - Clear

    func clear() {
        reportCache.removeAllObjects()
        recommendationCache.removeAllObjects()
    }
}
