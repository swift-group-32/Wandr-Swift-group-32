//
//  ReengagementStorage.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 26/11/26.
//

import Foundation
import SwiftData

@Model
final class SavedReengagementReport {
    @Attribute(.unique) var id: UUID
    var generatedAt: Date
    var savedAt: Date
    var reportData: Data

    init(
        id: UUID = UUID(),
        generatedAt: Date,
        savedAt: Date = Date(),
        reportData: Data
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.savedAt = savedAt
        self.reportData = reportData
    }
}

@MainActor
final class ReengagementStorage {

    private let container: ModelContainer
    private let context: ModelContext

    init() {
        do {
            let esquema = Schema([
                SavedReengagementReport.self
            ])

            let configuracion = ModelConfiguration(
                schema: esquema,
                isStoredInMemoryOnly: false
            )

            container = try ModelContainer(
                for: esquema,
                configurations: configuracion
            )

            context = ModelContext(container)

        } catch {
            fatalError("No se pudo crear el almacenamiento de Reengagement: \(error)")
        }
    }

    func save(_ report: ReengagementInsightsReport) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(report)

            let descriptor = FetchDescriptor<SavedReengagementReport>()

            let reportesExistentes = try context.fetch(descriptor)

            for reporte in reportesExistentes {
                context.delete(reporte)
            }

            let reporte = SavedReengagementReport(
                generatedAt: report.generatedAt,
                reportData: data
            )

            context.insert(reporte)
            try context.save()

        } catch {
            print("Error guardando Reengagement: \(error)")
        }
    }

    func load() -> ReengagementInsightsReport? {
        do {
            let descriptor = FetchDescriptor<SavedReengagementReport>(
                sortBy: [
                    SortDescriptor(\.savedAt, order: .reverse)
                ]
            )

            guard let reporte = try context.fetch(descriptor).first else {
                return nil
            }

            let decoder = JSONDecoder()
            return try decoder.decode(
                ReengagementInsightsReport.self,
                from: reporte.reportData
            )

        } catch {
            print("Error cargando Reengagement: \(error)")
            return nil
        }
    }

    func clear() {
        do {
            let descriptor = FetchDescriptor<SavedReengagementReport>()

            let reportes = try context.fetch(descriptor)

            for reporte in reportes {
                context.delete(reporte)
            }

            try context.save()

        } catch {
            print("Error eliminando Reengagement: \(error)")
        }
    }
}
