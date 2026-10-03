import SwiftUI
import PhotosUI

struct ActiveQuestView: View {
    @StateObject private var viewModel = ActiveQuestViewModel()
    @Environment(\.openURL) private var openURL
    @State private var showGiveUpConfirm = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoObjective: QuestObjective? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading your quest...")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text(error)
                        Button("Retry") {
                            Task { await viewModel.loadActiveQuest() }
                        }
                    }
                } else if let activeQuest = viewModel.activeQuest {
                    content(activeQuest)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.largeTitle)
                            .foregroundColor(.wandrSage)
                        Text("No active quest")
                            .font(.headline)
                            .foregroundColor(.wandrGreen)
                        Text("Start a quest to see your progress here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.wandrCream)
            .navigationTitle("Active Quest")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Give up this quest?", isPresented: $showGiveUpConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Give up", role: .destructive) {
                    Task { await viewModel.giveUp() }
                }
            } message: {
                Text("Your progress on this quest will be lost.")
            }
    
            .alert("Something went wrong", isPresented: Binding(
                get: { viewModel.actionError != nil },
                set: { if !$0 { viewModel.actionError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.actionError ?? "")
            }

            .alert("Quest completed! 🎉", isPresented: Binding(
                get: { viewModel.completionMessage != nil },
                set: { if !$0 { viewModel.completionMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.completionMessage ?? "")
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem = newItem, let objective = photoObjective else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await viewModel.submitPhoto(for: objective, imageData: data)
                    }
                    selectedPhoto = nil
                }
            }
        }
        .task {
            await viewModel.loadActiveQuest()
        }
    }

    func content(_ activeQuest: ActiveQuestDTO) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                statusCard(activeQuest)
                destinationCard(activeQuest.quest.place)
                objectivesSection()
                giveUpButton()
            }
            .padding()
        }
    }

    func statusCard(_ activeQuest: ActiveQuestDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In Progress")
                .font(.caption)
                .foregroundColor(.wandrGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.wandrSage.opacity(0.15))
                .cornerRadius(8)

            Text(activeQuest.quest.title)
                .font(.title2).bold()
                .foregroundColor(.wandrGreen)

            ProgressView(value: viewModel.progress)
                .tint(.wandrGreen)

            Text("\(viewModel.checkedCount) of \(viewModel.totalCount) steps done")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .cardStyle()
    }

    func destinationCard(_ place: PlaceInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESTINATION")
                .font(.caption2)
                .foregroundColor(.gray)

            Text(place.name)
                .font(.headline)
                .foregroundColor(.wandrGreen)

            if let address = place.address {
                Label(address, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Button {
                if let url = viewModel.navigationURL {
                    openURL(url)
                }
            } label: {
                Label("Navigate", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.wandrGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .cardStyle()
    }

    func objectivesSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("OBJECTIVES")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(viewModel.checkedCount) of \(viewModel.totalCount)")
                    .font(.caption).bold()
            }

            ForEach(viewModel.objectives) { objective in
                Button {
                    if objective.requiresPhoto {
                        guard !viewModel.isChecked(objective) else { return }
                        photoObjective = objective
                        showPhotoPicker = true
                    } else {
                        Task { await viewModel.checkObjective(objective) }
                    }
                } label: {
                    objectiveRow(objective)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isWorking)
            }
        }
    }

    func objectiveRow(_ objective: QuestObjective) -> some View {
        let done = viewModel.isChecked(objective)

        return HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.square.fill" : "square")
                .font(.title2)
                .foregroundColor(done ? .wandrGreen : .gray)

            VStack(alignment: .leading, spacing: 2) {
                Text(objective.title)
                    .strikethrough(done)
                    .foregroundColor(done ? .gray : .primary)
                Text(subtitle(for: objective, done: done))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if objective.requiresPhoto && !done {
                Image(systemName: "camera")
                    .foregroundColor(.gray)
            }
        }
        .cardStyle()
    }

    func subtitle(for objective: QuestObjective, done: Bool) -> String {
        if done {
            return "Done"
        } else if objective.requiresPhoto {
            return "Tap to take the photo"
        } else {
            return "Tap to check"
        }
    }

    func giveUpButton() -> some View {
        Button {
            showGiveUpConfirm = true
        } label: {
            Label("Give up quest", systemImage: "flag")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
        }
        .disabled(viewModel.isWorking)
    }
}

#Preview {
    ActiveQuestView()
}
