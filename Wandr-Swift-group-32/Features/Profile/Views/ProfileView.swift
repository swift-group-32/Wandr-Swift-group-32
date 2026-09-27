import SwiftUI
import Charts

// VIEW: solo dibuja. Todos los datos los saca del ViewModel.

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    let userId: String

    let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading your streak...")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text(error)
                        Button("Retry") {
                            Task { await viewModel.loadStreak(userId: userId) }
                        }
                    }
                } else if let profile = viewModel.profile {
                    content(profile)
                } else {
                    Text("No activity yet. Complete your first quest!")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.wandrCream)
            .navigationTitle("Profile")
        }
        .task {
            await viewModel.loadStreak(userId: userId)
        }
    }

    // Pantalla completa: las 4 tarjetas una debajo de otra
    func content(_ profile: StreakDTO) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                statsRow(profile)
                trendCard(profile)
                weekCard(profile)
                achievementsCard(profile)
            }
            .padding()
        }
    }

    // 1. Los tres números principales
    func statsRow(_ profile: StreakDTO) -> some View {
        HStack(spacing: 12) {
            statBox(value: "\(profile.streak.currentStreak)d", label: "Active Streak", icon: "flame.fill")
            statBox(value: "\(profile.stats.questsCompleted)", label: "Quests Done", icon: "checkmark.circle.fill")
            statBox(value: "\(profile.stats.points)", label: "Points", icon: "star.fill")
        }
    }

    func statBox(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.wandrSand)
            Text(value)
                .font(.title2).bold()
                .foregroundColor(.wandrGreen)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
    }

    // 2. BQ4: gráfico por semana + mensaje de comparación
    func trendCard(_ profile: StreakDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your streak trend")
                .font(.headline)
                .foregroundColor(.wandrGreen)

            Chart(profile.streak.weeklyHistory) { week in
                BarMark(
                    x: .value("Week", week.weekId),
                    y: .value("Quests", week.quests)
                )
                // La semana actual (la última) en verde fuerte, las demás más suaves
                .foregroundStyle(week.id == profile.streak.weeklyHistory.last?.id
                                 ? Color.wandrGreen
                                 : Color.wandrSage.opacity(0.5))
                .cornerRadius(6)
                // Numerito encima de cada barra
                .annotation(position: .top) {
                    Text("\(week.quests)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 160)

            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text(viewModel.comparisonMessage)
            }
            .font(.subheadline)
            .foregroundColor(.wandrGreen)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.wandrSand.opacity(0.2))
            .cornerRadius(10)
        }
        .cardStyle()
    }

    // 3. Los 7 días de esta semana
    func weekCard(_ profile: StreakDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly flow")
                .font(.headline)
                .foregroundColor(.wandrGreen)

            HStack {
                ForEach(0..<profile.streak.thisWeek.count, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text(i < dayLetters.count ? dayLetters[i] : "")
                            .font(.caption)
                            .foregroundColor(.gray)
                        ZStack {
                            Circle()
                                .fill(profile.streak.thisWeek[i] ? Color.wandrGreen : Color.gray.opacity(0.2))
                                .frame(width: 34, height: 34)
                            if profile.streak.thisWeek[i] {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    // 4. Logros
    func achievementsCard(_ profile: StreakDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundColor(.wandrGreen)

            HStack(spacing: 12) {
                ForEach(profile.achievements) { achievement in
                    VStack(spacing: 8) {
                        Image(systemName: achievement.unlocked ? "rosette" : "lock.fill")
                            .font(.title2)
                            .foregroundColor(achievement.unlocked ? .white : .gray)
                            .frame(width: 52, height: 52)
                            .background(achievement.unlocked ? Color.wandrGreen : Color.gray.opacity(0.15))
                            .cornerRadius(14)
                        Text(achievement.name)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    ProfileView(userId: "123")
}
