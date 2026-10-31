import SwiftUI

struct BusinessInsightsView: View {
    @StateObject private var viewModel: BusinessInsightsViewModel

    init(viewModel: BusinessInsightsViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? BusinessInsightsViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("businessError")
                }

                if viewModel.access == .inactive {
                    activationCard
                } else if let report = viewModel.report {
                    reportContent(report)
                } else if !viewModel.isWorking {
                    ContentUnavailableView(
                        "Report unavailable",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Try again to load sponsorship insights.")
                    )
                }

                if viewModel.isWorking {
                    ProgressView(viewModel.access == .inactive ? "Activating access…" : "Loading insights…")
                        .frame(maxWidth: .infinity)
                } else if viewModel.access != .inactive {
                    Button("Refresh report", systemImage: "arrow.clockwise") {
                        Task { await viewModel.load() }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .background(Color.wandrCream)
        .tint(.wandrGreen)
        .navigationTitle("Business Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var activationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "briefcase")
                .font(.largeTitle)
                .foregroundStyle(Color.wandrGreen)
            Text("Discover sponsorship opportunities")
                .font(.title2.bold())
            Text("See which quest categories attract the most engagement. Enter your business access code to view the report.")
                .foregroundStyle(.secondary)
            SecureField("Business access code", text: $viewModel.accessCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .submitLabel(.go)
                .accessibilityIdentifier("businessAccessCode")
                .onSubmit { Task { await viewModel.activate() } }
                .disabled(viewModel.isWorking)
            Button {
                Task { await viewModel.activate() }
            } label: {
                Text("Activate business access")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isWorking || viewModel.accessCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("activateBusinessAccess")
        }
        .cardStyle()
    }

    private func reportContent(_ report: CategoryEngagementReport) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Sponsorship opportunities", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Color.wandrGreen)
                Text(report.recommendation)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("businessRecommendation")
                Text("\(report.windowStart.formatted(date: .abbreviated, time: .omitted)) – \(report.windowEnd.formatted(date: .abbreviated, time: .omitted)) · 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: 16) {
                Text("Category engagement").font(.headline)
                Text("Ranked by completed quests, then by unique participants. Equal results share a rank.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(report.rankedCategories) { category in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            if let rank = report.rank(for: category) {
                                Text("\(rank)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(Color.wandrSage)
                                    .frame(minWidth: 24, alignment: .leading)
                            }
                            Text(category.name).font(.headline)
                            Spacer()
                        }
                        Text("\(category.completedQuests) completed quests · \(category.uniqueParticipants) participants")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    if category.id != report.rankedCategories.last?.id { Divider() }
                }
            }
            .cardStyle()

            Text("Engagement highlights potential sponsorship opportunities; it does not predict revenue.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Updated \(report.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack { BusinessInsightsView() }
}
