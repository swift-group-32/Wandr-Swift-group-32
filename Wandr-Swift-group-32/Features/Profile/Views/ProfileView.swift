import SwiftUI
import Charts

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
            .toolbar {
                // Current streak, next to the title
                ToolbarItem(placement: .topBarTrailing) {
                    if let profile = viewModel.profile {
                        Label("\(profile.streak.currentStreak)", systemImage: "flame.fill")
                            .font(.subheadline).bold()
                            .foregroundColor(.wandrGreen)
                    }
                }
            }
        }
        .task {
            await viewModel.loadStreak(userId: userId)
        }
    }

    func content(_ profile: StreakDTO) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                levelCard()
                weekCard(profile)
                trendCard(profile)
                achievementsSection(profile)
            }
            .padding()
        }
    }

    // 1. Next milestone: progress to the next level
    func levelCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NEXT MILESTONE")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(viewModel.xpToGo) pts to go")
                    .font(.caption).bold()
                    .foregroundColor(.wandrGreen)
            }
            HStack {
                Text("Level \(viewModel.nextLevel)")
                    .font(.title2).bold()
                    .foregroundColor(.wandrGreen)
                Spacer()
                Text("\(viewModel.xpIntoLevel) / \(viewModel.xpPerLevel) XP")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            ProgressView(value: viewModel.levelProgress)
                .tint(.wandrGreen)
        }
        .cardStyle()
    }

    func weekCard(_ profile: StreakDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS WEEK")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(viewModel.activeDaysCount)/7 days")
                    .font(.caption).bold()
                    .foregroundColor(.wandrGreen)
            }

            HStack {
                ForEach(0..<profile.streak.thisWeek.count, id: \.self) { i in
                    let isActive = profile.streak.thisWeek[i]
                    let isToday = i == viewModel.todayIndex

                    VStack(spacing: 6) {
                        Text(i < dayLetters.count ? dayLetters[i] : "")
                            .font(.caption)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundColor(isToday ? .wandrGreen : .gray)

                        ZStack {
                            if isActive {
                                Circle().fill(Color.wandrGreen)
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            } else {
                                Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                            }
                        }
                        .frame(width: 34, height: 34)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    func trendCard(_ profile: StreakDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("QUESTS PER WEEK")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text("Last 4 weeks")
                    .font(.caption).bold()
                    .foregroundColor(.wandrGreen)
            }

            Chart(profile.streak.weeklyHistory) { week in
                BarMark(
                    x: .value("Week", viewModel.weekLabel(week)),
                    y: .value("Quests", week.quests)
                )
                .foregroundStyle(week.id == profile.streak.weeklyHistory.last?.id
                                 ? Color.wandrGreen
                                 : Color.wandrSage.opacity(0.4))
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text("\(week.quests)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 160)

            HStack(alignment: .top, spacing: 8) {
                if let difference = viewModel.weekDifference {
                    differencePill(difference)
                }
                Text(viewModel.comparisonMessage)
                    .font(.subheadline)
                    .foregroundColor(.wandrGreen)
            }
        }
        .cardStyle()
    }

    func differencePill(_ difference: Int) -> some View {
        let color: Color = difference > 0 ? .wandrGreen : (difference < 0 ? .red : .gray)
        let icon = difference > 0 ? "arrow.up.right" : (difference < 0 ? "arrow.down.right" : "equal")
        let text = difference > 0 ? "+\(difference)" : "\(difference)"

        return Label(text, systemImage: icon)
            .font(.caption).bold()
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(8)
    }

    func achievementsSection(_ profile: StreakDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.title3).bold()
                    .foregroundColor(.wandrGreen)
                Text("\(viewModel.unlockedCount)/\(viewModel.totalBadges)")
                    .font(.caption).bold()
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(8)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(profile.achievements) { achievement in
                    badgeCard(achievement)
                }
            }
        }
    }

    func badgeCard(_ achievement: Achievement) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: achievement.unlocked ? "trophy.fill" : "lock.fill")
                .foregroundColor(achievement.unlocked ? .wandrGreen : .gray)
                .frame(width: 40, height: 40)
                .background(achievement.unlocked ? Color.wandrSage.opacity(0.15) : Color.gray.opacity(0.15))
                .clipShape(Circle())

            Text(achievement.name)
                .font(.subheadline).bold()
                .foregroundColor(achievement.unlocked ? .primary : .gray)

            Text(viewModel.badgeSubtitle(achievement))
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(2)

            if achievement.unlocked {
                Text("Completed")
                    .font(.caption2).bold()
                    .foregroundColor(.wandrGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.wandrSage.opacity(0.15))
                    .cornerRadius(8)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(achievement.unlocked ? Color.white : Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
}

#Preview {
    ProfileView(userId: "123")
}
