import SwiftUI

struct LowUseCategoriesView: View {
    @ObservedObject private var network = NetworkMonitor.shared
    @StateObject private var model = LowUseCategoriesViewModel()

    var body: some View {
        List {
            if model.status == .offline || model.status == .failed {
                Section {
                    connectionNotice
                }
            }

            if let report = model.report {
                Section {
                    Text("Categorías con menos de tres inicios de quest por semana en promedio durante las últimas cuatro semanas completas.")
                    LabeledContent("Última actualización", value: report.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    if model.status == .loading {
                        ProgressView("Actualizando…")
                    }
                }

                if report.categories.isEmpty {
                    Section {
                        ContentUnavailableView("No hay categorías de bajo uso", systemImage: "chart.bar.xaxis",
                                               description: Text("Todas alcanzaron al menos tres inicios por semana en promedio."))
                    }
                } else {
                    ForEach(report.categories) { category in
                        Section(category.tagName) {
                            LabeledContent("Inicios en cuatro semanas", value: category.totalStarts.formatted())
                            LabeledContent("Promedio semanal", value: category.averagePerWeek.formatted(
                                .number.precision(.fractionLength(0...2))
                            ))
                            ForEach(category.weeklyBreakdown) { week in
                                LabeledContent("Semana del \(displayDate(week.weekStart))", value: week.starts.formatted())
                            }
                        }
                    }
                }
            } else if model.status == .loading {
                Section {
                    ProgressView("Cargando informe…")
                }
            } else if model.status == .accessDenied {
                Section {
                    ContentUnavailableView("Informe no disponible", systemImage: "lock",
                                           description: Text("Se requiere una sesión con acceso a este informe."))
                }
            }
        }
        .navigationTitle("Categorías de bajo uso")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: network.isConnected) {
            await model.load(connected: network.isConnected)
        }
        .refreshable {
            await model.load(connected: network.isConnected, force: true)
        }
    }

    private var connectionNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(model.status == .offline ? "Sin conexión" : "No se pudo actualizar el informe",
                  systemImage: model.status == .offline ? "wifi.slash" : "exclamationmark.circle")
                .font(.headline)

            if model.report != nil {
                Text("Se muestran los últimos resultados guardados.")
            } else if model.status == .offline {
                Text("Conéctate a internet para cargar el informe por primera vez.")
            }

            Button("Reintentar") {
                Task { await model.load(connected: network.isConnected, force: true) }
            }
        }
    }

    private func displayDate(_ date: String) -> String {
        let parts = date.split(separator: "-")
        guard parts.count == 3 else { return date }
        return "\(parts[2])/\(parts[1])/\(parts[0])"
    }
}
