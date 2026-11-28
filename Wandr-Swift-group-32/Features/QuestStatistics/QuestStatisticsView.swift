import Charts
import SwiftUI

struct QuestStatisticsView: View {
    @ObservedObject private var network = NetworkMonitor.shared
    @StateObject private var model = QuestStatisticsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let report = model.report {
                    if model.status == .offline || model.status == .failed {
                        connectionNotice(hasReport: true)
                    }
                    summary(report)
                    categories(report)
                    activity(report)
                    months(report)
                } else {
                    switch model.status {
                    case .loading:
                        ProgressView("Cargando estadísticas…")
                            .frame(maxWidth: .infinity)
                    case .offline, .failed:
                        connectionNotice(hasReport: false)
                    case .signedOut:
                        ContentUnavailableView("Inicia sesión", systemImage: "person.crop.circle",
                                               description: Text("Entra a tu cuenta para ver tus estadísticas."))
                    case .ready:
                        EmptyView()
                    }
                }
            }
            .padding()
        }
        .background(Color.wandrCream)
        .navigationTitle("Mis estadísticas")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: network.isConnected) {
            await model.load(connected: network.isConnected)
        }
        .refreshable {
            await model.load(connected: network.isConnected, force: true)
        }
    }

    private func connectionNotice(hasReport: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(model.status == .offline ? "Sin conexión" : "Error al actualizar",
                  systemImage: model.status == .offline ? "wifi.slash" : "exclamationmark.circle")
                .font(.headline)
            if hasReport, let report = model.report {
                Text("Última actualización: \(report.updatedAt.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("Conéctate a internet para cargar tus estadísticas.")
            }
            Button("Reintentar") {
                Task { await model.load(connected: network.isConnected, force: true) }
            }
            .buttonStyle(.bordered)
            .tint(.wandrGreen)
        }
        .cardStyle()
    }

    private func summary(_ report: QuestStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("Resumen")
            metric("Quests completadas", report.completed.formatted())
            metric("Quests abandonadas", report.abandoned.formatted())
            metric("Tasa de finalización", report.completionRate.map(percent) ?? "—")
            metric("Lugares únicos visitados", report.uniquePlaces.formatted())
            metric("Distancia aproximada", report.distanceKilometers.map {
                "≈ \($0.formatted(.number.precision(.fractionLength(1)))) km"
            } ?? "—")
            Text("Distancia en línea recta entre lugares de quests completadas consecutivas.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if report.completed == 0, report.abandoned == 0 {
                Text("Todavía no tienes quests finalizadas.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private func categories(_ report: QuestStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("Categorías favoritas")
            if report.categories.isEmpty {
                Text("Aún no hay categorías para mostrar.")
                    .foregroundStyle(.secondary)
            }
            ForEach(report.categories) { category in
                metric(category.name.capitalized, percent(category.share))
            }
        }
        .cardStyle()
    }

    private func activity(_ report: QuestStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("Horas activas")
            Text("Según la hora de finalización en Bogotá.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            let busiest = report.busiestBands
            let maximum = max(1, report.activity.values.max() ?? 0)
            ForEach(QuestStatistics.TimeBand.allCases, id: \.self) { band in
                let count = report.activity[band, default: 0]
                VStack(alignment: .leading, spacing: 5) {
                    metric(band.title, count.formatted())
                        .fontWeight(busiest.contains(band) ? .semibold : .regular)
                    ProgressView(value: Double(count), total: Double(maximum))
                        .tint(busiest.contains(band) ? .wandrGreen : .wandrSage)
                        .accessibilityHidden(true)
                }
            }
            if !busiest.isEmpty {
                let bands = busiest.map(\.title).joined(separator: ", ")
                Text("Mayor actividad: \(bands)")
                    .font(.footnote.bold())
                    .foregroundStyle(Color.wandrGreen)
            }
        }
        .cardStyle()
    }

    private func months(_ report: QuestStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("Quests por mes")
            Chart(report.months) { month in
                let label = monthLabel(month.start)
                BarMark(
                    x: .value("Mes", label),
                    y: .value("Completadas", month.count)
                )
                .foregroundStyle(Color.wandrGreen)
                .annotation(position: .top) {
                    Text(month.count.formatted())
                        .font(.caption2)
                }
                .accessibilityLabel(label)
                .accessibilityValue(month.count.formatted())
            }
            .chartYScale(domain: 0...max(1, (report.months.map(\.count).max() ?? 0) + 1))
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 156)
        }
        .cardStyle()
    }

    private func metric(_ title: String, _ value: String) -> some View {
        LabeledContent(title, value: value)
            .monospacedDigit()
            .accessibilityElement(children: .combine)
    }

    private func heading(_ title: String) -> some View {
        Text(title).font(.headline)
            .foregroundStyle(Color.wandrGreen)
            .accessibilityAddTraits(.isHeader)
    }

    private func percent(_ share: Double) -> String {
        share.formatted(.percent.precision(.fractionLength(0...1)))
    }

    private func monthLabel(_ date: Date) -> String {
        let style = Date.FormatStyle(locale: Locale(identifier: "es_CO"), timeZone: QuestStatistics.bogota)
            .month(.abbreviated)
        return date.formatted(style)
    }
}
