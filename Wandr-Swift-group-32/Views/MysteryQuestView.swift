import SwiftUI

struct MysteryQuestView: View {

    @Binding var selectedTab: AppTab

    @State private var energyLevel = "Balanced"
    @State private var quest: Quest?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let repository = SupabaseQuestRepository()

    private let energyLevels = [
        "Low",
        "Balanced",
        "High"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Image

                    Image("MysteryQuestImage")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 220)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 24)
                        )

                    // MARK: - Header

                    VStack(spacing: 8) {
                        Text("Mystery Quest")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.wandrGreen)

                        Text(
                            "Discover something unexpected based on your energy level."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    }

                    // MARK: - Energy Level

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Energy level")
                            .font(.headline)
                            .foregroundStyle(Color.wandrGreen)

                        HStack(spacing: 10) {
                            ForEach(energyLevels, id: \.self) { level in

                                Button {
                                    energyLevel = level
                                } label: {
                                    Text(level)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(
                                            energyLevel == level
                                            ? .white
                                            : Color.wandrGreen
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            energyLevel == level
                                            ? Color.wandrGreen
                                            : Color.wandrSage.opacity(0.25)
                                        )
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 12
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // MARK: - Reveal Quest

                    Button {
                        Task {
                            await loadMysteryQuest()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }

                            Text(
                                isLoading
                                ? "Finding a quest..."
                                : "Reveal Quest"
                            )
                            .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.wandrGreen)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .disabled(isLoading)

                    // MARK: - Error

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Quest

                    if let quest {
                        mysteryQuestCard(quest)
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color.wandrCream)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if quest == nil {
                    await loadMysteryQuest()
                }
            }
        }
    }

    // MARK: - Mystery Quest Card

    private func mysteryQuestCard(_ quest: Quest) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Label(
                    quest.category.uppercased(),
                    systemImage: "sparkles"
                )
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.wandrSage)

                Spacer()

                Text("\(quest.duration) min")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Text(quest.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.wandrGreen)

            Text(quest.description)
                .font(.body)
                .foregroundStyle(.secondary)

            // MARK: Accept

            Button {
                selectedTab = .quest
            } label: {
                HStack {
                    Text("Accept Quest")

                    Spacer()

                    Image(systemName: "arrow.right")
                }
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color.wandrGreen)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
            }

            // MARK: Try Another

            Button {
                Task {
                    await loadMysteryQuest()
                }
            } label: {
                Text("Try Another")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.wandrGreen)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Load Mystery Quest

    private func loadMysteryQuest() async {
        isLoading = true
        errorMessage = nil

        do {
            quest = try await repository.getMysteryQuest(
                energyLevel: energyLevel
            )
        } catch {
            quest = nil
            errorMessage = "We couldn't find a Mystery Quest right now."
        }

        isLoading = false
    }
}
