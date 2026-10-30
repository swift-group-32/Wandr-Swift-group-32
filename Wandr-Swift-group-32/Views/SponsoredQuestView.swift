//
//  SponsoredQuestView.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import SwiftUI

struct SponsoredQuestView: View {

    @StateObject private var viewModel =
        SponsoredQuestViewModel(
            repository: SupabaseSponsoredQuestRepository()
        )
    @StateObject private var connectivity = ConnectivityMonitor.shared

    @State private var selectedQuest: Quest?

    var body: some View {
        Group {
            if viewModel.isLoading {

                ProgressView("Loading...")

            } else if let error = viewModel.errorMessage {

                VStack(spacing: 12) {
                    Text("Could not load data")
                        .font(.headline)

                    Text(error)
                        .font(.caption)
                        .multilineTextAlignment(.center)

                    Button("Retry") {
                        Task {
                            await viewModel.loadCurrentUser()
                        }
                    }
                }
                .padding()

            } else if let user = viewModel.activeUser {

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(
                                "\(user.completedQuests) quests completed this month"
                            )
                            .font(.headline)

                            if user.hasTriedSponsoredQuest {
                                Text(
                                    "You have already tried a sponsored quest"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            } else {
                                Text(
                                    "You haven't tried a sponsored quest yet"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(Color.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 18)
                        )

                        if !user.hasTriedSponsoredQuest,
                           let sponsoredQuest = user.sponsoredQuest {

                            VStack(
                                alignment: .leading,
                                spacing: 12
                            ) {

                                HStack {
                                    Image(
                                        systemName: "megaphone.fill"
                                    )
                                    .foregroundStyle(
                                        Color("WandrSecondary")
                                    )

                                    Text("Sponsored for you")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(
                                            Color("WandrSecondary")
                                        )

                                    Spacer()
                                }

                                Button {
                                    selectedQuest = makeQuest(
                                        from: sponsoredQuest
                                    )
                                } label: {

                                    HStack(spacing: 14) {

                                        ZStack {
                                            RoundedRectangle(
                                                cornerRadius: 14
                                            )
                                            .fill(
                                                Color("WandrSecondary")
                                            )

                                            Image(
                                                systemName: "music.note"
                                            )
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                        }
                                        .frame(
                                            width: 64,
                                            height: 64
                                        )

                                        VStack(
                                            alignment: .leading,
                                            spacing: 5
                                        ) {

                                            Text(
                                                sponsoredQuest.title
                                            )
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(
                                                Color("WandrPrimary")
                                            )
                                            .lineLimit(2)

                                            Text(
                                                "Sponsored by \(sponsoredQuest.sponsorName)"
                                            )
                                            .font(.caption)
                                            .foregroundStyle(
                                                Color("WandrSecondary")
                                            )

                                            HStack(spacing: 5) {
                                                Image(
                                                    systemName: "clock"
                                                )

                                                Text(
                                                    "\(sponsoredQuest.duration) min"
                                                )

                                                Spacer()

                                                Image(
                                                    systemName:
                                                        "chevron.right"
                                                )
                                            }
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 18
                                        )
                                    )
                                }
                                .buttonStyle(.plain)

                                Text(
                                    "Recommended because you completed \(user.completedQuests) quests this month."
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }

            } else {

                VStack(spacing: 12) {
                    Text("No sponsored quest opportunity")
                        .font(.headline)

                    Text(
                        "Complete at least 5 quests this month to see sponsored quest opportunities."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .background(Color.wandrCream)
        .navigationTitle("Sponsored Quest")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadCurrentUser()
        }
        .onChange(of: connectivity.isConnected) { _, connected in
            if connected {
                Task {
                    await viewModel.loadCurrentUser()
                }
            }
        }
        .sheet(item: $selectedQuest) { quest in
            ExploreQuestDetailsView(
                quest: quest,
                isSaved: false,
                onSave: { _, _ in }
            )
        }
    }

    private func makeQuest(
        from sponsoredQuest: SponsoredQuest
    ) -> Quest {

        Quest(
            id: sponsoredQuest.id.uuidString,
            title: sponsoredQuest.title,
            category: sponsoredQuest.category,
            description: sponsoredQuest.description,
            duration: sponsoredQuest.duration,
            rating: sponsoredQuest.rating,
            isCompleted: false,
            isSaved: false
        )
    }
}

#Preview {
    SponsoredQuestView()
}
