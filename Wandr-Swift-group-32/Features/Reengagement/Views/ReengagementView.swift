//
//  ReengagementView.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 26/11/26.
//

import SwiftUI

struct ReengagementView: View {

    @StateObject private var viewModel = ReengagementViewModel()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    var body: some View {

        NavigationStack {

            Group {

                if viewModel.isLoading && viewModel.reporte == nil {

                    ProgressView("Loading analysis...")

                } else if let errorMessage = viewModel.errorMessage {

                    VStack(spacing: 12) {

                        Text(errorMessage)
                            .multilineTextAlignment(.center)

                        Button("Retry") {
                            Task {
                                await viewModel.cargar()
                            }
                        }
                    }
                    .padding()

                } else if let reporte = viewModel.reporte {

                    contenido(reporte)

                } else {

                    ContentUnavailableView(
                        "No Users Identified",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text(
                            "No users currently meet the re-engagement criteria."
                        )
                    )
                }
            }
            .navigationTitle("Reengagement Insights")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.cargar()
            }
            .onChange(of: networkMonitor.isConnected) { _, conectado in

                Task {
                    await viewModel.cambioConectividad(conectado)
                }
            }
        }
    }

    @ViewBuilder
    private func contenido(
        _ reporte: ReengagementInsightsReport
    ) -> some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 16) {

                if !networkMonitor.isConnected {

                    Text("You're offline. Showing saved analysis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(.thinMaterial)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )

                } else if let offlineMessage = viewModel.offlineMessage {

                    Text(offlineMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(.thinMaterial)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {

                    Label(
                        "Users likely to re-engage",
                        systemImage: "person.crop.circle.badge.plus"
                    )
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.wandrGreen)

                    Text(
                        "\(usuariosAgrupados(reporte).count) users identified"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(Color.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )

                if !reporte.recommendations.isEmpty {

                    VStack(alignment: .leading, spacing: 12) {

                        Text("Re-engagement recommendations")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(
                            "Personalized sponsored quests for users whose activity has declined."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        ForEach(
                            usuariosAgrupados(reporte),
                            id: \.userId
                        ) { usuario in

                            userCard(usuario)
                        }
                    }
                }

                Button {

                    Task {
                        await viewModel.cargar(
                            forzarActualizacion: true
                        )
                    }

                } label: {

                    Label(
                        "Refresh report",
                        systemImage: "arrow.clockwise"
                    )
                    .font(.subheadline)
                    .foregroundStyle(Color.wandrGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Color.wandrSage.opacity(0.3)
                    )
                    .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .background(Color.wandrCream)
        .refreshable {
            await viewModel.cargar()
        }
    }

    // MARK: - Group users

    private func usuariosAgrupados(
        _ reporte: ReengagementInsightsReport
    ) -> [UserReengagementGroup] {

        let agrupaciones = Dictionary(
            grouping: reporte.recommendations,
            by: { $0.userId }
        )

        return agrupaciones.values.compactMap { recomendaciones in

            guard let primera = recomendaciones.first else {
                return nil
            }

            return UserReengagementGroup(
                userId: primera.userId,
                userName: primera.userName,
                activityDropPercentage: primera.activityDropPercentage,
                preferredCategory: primera.preferredCategory,
                recommendations: recomendaciones.sorted {
                    $0.reengagementLikelihood > $1.reengagementLikelihood
                }
            )
        }
        .sorted {
            let probabilidad1 =
                $0.recommendations.first?.reengagementLikelihood ?? 0

            let probabilidad2 =
                $1.recommendations.first?.reengagementLikelihood ?? 0

            return probabilidad1 > probabilidad2
        }
    }

    // MARK: - User Card

    private func userCard(
        _ usuario: UserReengagementGroup
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Text(usuario.userName)
                    .font(.headline)

                Spacer()

                Text(
                    "\(usuario.activityDropPercentage, specifier: "%.1f")% drop"
                )
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.wandrGreen)
            }

            Divider()

            VStack(alignment: .leading, spacing: 5) {

                Text("Preferred category")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(usuario.preferredCategory)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text("Possible sponsored quests")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 4)

            VStack(spacing: 10) {

                ForEach(
                    usuario.recommendations
                ) { recommendation in

                    sponsoredQuestRow(recommendation)
                }
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(Color.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    // MARK: - Sponsored Quest Row

    private func sponsoredQuestRow(
        _ recommendation: ReengagementRecommendation
    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack(alignment: .top) {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(recommendation.recommendedQuestTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(recommendation.recommendedQuestDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(
                        recommendation.sponsorName,
                        systemImage: "building.2"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text(
                    "\(recommendation.reengagementLikelihood, specifier: "%.1f")%"
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.wandrGreen)
            }
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(Color(.systemGray6))
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
    }
}

// MARK: - User Group

private struct UserReengagementGroup {

    let userId: UUID
    let userName: String
    let activityDropPercentage: Double
    let preferredCategory: String
    let recommendations: [ReengagementRecommendation]
}
