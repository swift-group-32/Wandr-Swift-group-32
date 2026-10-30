import SwiftUI


struct AboutYouView: View {
    @StateObject private var viewModel = AboutYouViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text("This helps us recommend better quests. All answers are optional and you can change them anytime.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let message = viewModel.message {
                Section {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Section("You") {
                Picker("Age range", selection: $viewModel.ageRange) {
                    Text("Select").tag("")
                    Text("Prefer not to say").tag(AboutYouViewModel.preferNotToSay)
                    ForEach(viewModel.ageOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                Picker("Occupation", selection: $viewModel.occupation) {
                    Text("Select").tag("")
                    Text("Prefer not to say").tag(AboutYouViewModel.preferNotToSay)
                    ForEach(viewModel.occupationOptions, id: \.self) { option in
                        Text(viewModel.label(option)).tag(option)
                    }
                }
            }

            Section("Notifications") {
                // Sponsored quest notifications (BQ13) respect this option
                Toggle("Receive notifications", isOn: $viewModel.notificationsEnabled)
                    .tint(.wandrGreen)
            }

            Section {
                Button {
                    Task { await viewModel.save() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.isSaving || viewModel.isLoading)
                .tint(.wandrGreen)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.wandrCream)
        .navigationTitle("About you")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
        }
    }
}

#Preview {
    NavigationStack {
        AboutYouView()
    }
}
