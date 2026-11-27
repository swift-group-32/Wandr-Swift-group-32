import Foundation
import SwiftUI
import Combine

@MainActor
final class ReengagementViewModel: ObservableObject {

    @Published var reporte: ReengagementInsightsReport?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var offlineMessage: String?

    private let servicio: ReengagementInsightsServing
    private let cache = ReengagementInsightsCache.shared
    private let storage = ReengagementStorage()

    init(
        servicio: ReengagementInsightsServing? = nil
    ) {
        self.servicio = servicio ?? ReengagementInsightsService()
    }

    func cargar(
        forzarActualizacion: Bool = false
    ) async {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        // 1. Intentar usar el cache en memoria.
        if !forzarActualizacion,
           let reporteCacheado = cache.loadReport() {

            reporte = reporteCacheado
            offlineMessage = nil
            isLoading = false
            return
        }

        // 2. Intentar cargar almacenamiento persistente.
        if reporte == nil,
           let reporteGuardado = storage.load() {

            reporte = reporteGuardado
            cache.saveReport(reporteGuardado)
        }

        // 3. Si no hay conexión, usar los datos guardados.
        guard NetworkMonitor.shared.isConnected else {
            offlineMessage = reporte == nil
                ? "You're offline and there is no saved analysis."
                : "You're offline. Showing saved analysis."

            isLoading = false
            return
        }

        // 4. Consultar Supabase.
        do {
            let reporteActualizado = try await servicio.fetchInsights()

            reporte = reporteActualizado

            // Guardar en cache y almacenamiento persistente.
            cache.saveReport(reporteActualizado)
            storage.save(reporteActualizado)

            offlineMessage = nil
            errorMessage = nil

        } catch {
            if reporte != nil {
                offlineMessage = "Unable to refresh. Showing saved analysis."
            } else {
                errorMessage = "Unable to load re-engagement analysis."
            }
        }

        isLoading = false
    }

    func cambioConectividad(
        _ conectado: Bool
    ) async {

        if !conectado {
            offlineMessage = reporte == nil
                ? "You're offline and there is no saved analysis."
                : "You're offline. Showing saved analysis."
            return
        }

        guard reporte != nil else {
            return
        }

        // Al volver la conexión, forzamos actualización.
        await cargar(forzarActualizacion: true)
    }

    func limpiar() {
        reporte = nil
        cache.clear()
        storage.clear()
        offlineMessage = nil
        errorMessage = nil
    }
}
