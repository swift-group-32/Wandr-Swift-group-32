import SwiftUI


struct ProfileCompletionCard: View {
    let hasPhoto: Bool

    @StateObject private var viewModel = AboutYouViewModel()

    
    @AppStorage("profileCardHiddenUntil") private var hiddenUntil: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            if shouldShow {
                card()
            }
        }
        .task {
            await viewModel.load()
        }
    }

    var shouldShow: Bool {
        
        guard viewModel.savedInfo != nil else { return false }
        if Date().timeIntervalSince1970 < hiddenUntil { return false }
        return !viewModel.missingItems(hasPhoto: hasPhoto).isEmpty
    }

    func card() -> some View {
        let completion = viewModel.completion(hasPhoto: hasPhoto)
        let missing = viewModel.missingItems(hasPhoto: hasPhoto)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: completion)
                        .stroke(Color.wandrSand, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(completion * 100))%")
                        .font(.caption).bold()
                        .foregroundColor(.white)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your profile is \(Int(completion * 100))% complete")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Add \(missing.joined(separator: ", ")) so we can find quests made for you.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
            }

            HStack {
                NavigationLink {
                    AboutYouView()
                } label: {
                    Text("Complete profile")
                        .font(.subheadline).bold()
                        .foregroundColor(.wandrGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(20)
                }

                Spacer()

                Button("Not now") {
                    hiddenUntil = Date().addingTimeInterval(3 * 24 * 60 * 60).timeIntervalSince1970
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wandrGreen)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        ProfileCompletionCard(hasPhoto: false)
            .padding()
    }
}
