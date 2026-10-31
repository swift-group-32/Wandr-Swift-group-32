import SwiftUI
import Charts
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    @EnvironmentObject var auth: AuthViewModel
    let userId: String

    let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    @State private var selectedPhoto: PhotosPickerItem? = nil
    
    @State private var showPhotoOptions = false
    
    @State private var showPhotoPicker = false
    
    @State private var showLogOutConfirm = false

    var body: some View {
        NavigationStack {

            Group {

                if viewModel.isLoading {

                    ProgressView("Loading your streak...")

                } else if let error = viewModel.errorMessage {

                    VStack(spacing: 12) {

                        Text(error)

                        Button("Retry") {
                            Task {
                                await viewModel.loadStreak(userId: userId)
                            }
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
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem = newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await viewModel.changePhoto(imageData: data)
                    }
                    selectedPhoto = nil
                }
            }
            .alert("Log out?", isPresented: $showLogOutConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Log out", role: .destructive) {
                    Task { await auth.logOut() }
                }
            } message: {
                Text("You will need your email and password to come back.")
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { viewModel.photoError != nil },
                set: { if !$0 { viewModel.photoError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.photoError ?? "")
            }
        }
        .task {
            await viewModel.loadStreak(userId: userId)
            await viewModel.loadUser()
        }
    }

    func content(_ profile: StreakDTO) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                profileHeader(profile)
                ProfileCompletionCard(hasPhoto: viewModel.photoURL != nil)
                levelCard()
                weekCard(profile)
                trendCard(profile)
                achievementsSection(profile)

                NavigationLink {
                    SponsoredQuestView()
                } label: {
                    HStack {
                        Image(systemName: "megaphone.fill")
                            .foregroundStyle(Color.wandrGreen)

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text("Sponsored Quest Opportunities")
                                .font(.headline)

                            Text("Find users for sponsored quests")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(16)
                }

                insightsLink()

                logOutButton()
                
            }
            .padding()
        }
    }

    func profileHeader(_ profile: StreakDTO) -> some View {
        HStack(spacing: 16) {
            Button {
                showPhotoOptions = true
            } label: {
                avatarImage()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay {
                        // While the photo uploads, a spinner covers the avatar
                        if viewModel.isUploadingPhoto {
                            Circle().fill(Color.black.opacity(0.35))
                            ProgressView().tint(.white)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isUploadingPhoto)
            .confirmationDialog("Profile photo", isPresented: $showPhotoOptions) {
                Button("Choose from library") {
                    showPhotoPicker = true
                }
                if viewModel.photoURL != nil {
                    Button("Remove photo", role: .destructive) {
                        Task { await viewModel.removePhoto() }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.user?.name ?? "Explorer")
                    .font(.title3).bold()
                    .foregroundColor(.wandrGreen)

                Text("Level \(profile.stats.level)")
                    .font(.caption).bold()
                    .foregroundColor(.wandrGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.wandrSage.opacity(0.15))
                    .cornerRadius(8)

                if let badge = viewModel.latestBadge {
                    Label("\(badge.name) · \(badge.earnedOn ?? "")", systemImage: "trophy.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Label("No badges yet", systemImage: "trophy")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .cardStyle()
    }

    // The user's photo if they have one if not, their bear avatar
    @ViewBuilder
    func avatarImage() -> some View {
        if let url = viewModel.photoURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    defaultAvatar()
                } else {
                    ProgressView()
                }
            }
        } else {
            defaultAvatar()
        }
    }

    func defaultAvatar() -> some View {
        Image(viewModel.defaultAvatarName)
            .resizable()
            .scaledToFill()
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
                VStack(alignment: .leading, spacing: 2) {
                    Text("THIS WEEK")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Label("\(profile.streak.currentStreak)-day streak", systemImage: "flame.fill")
                        .font(.subheadline).bold()
                        .foregroundColor(.wandrGreen)
                }
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

    // BQ9
    func insightsLink() -> some View {
        NavigationLink {
            ActivityInsightsView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(.wandrGreen)
                    .frame(width: 40, height: 40)
                    .background(Color.wandrSage.opacity(0.15))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity insights")
                        .font(.subheadline).bold()
                        .foregroundColor(.wandrGreen)
                    Text("What inactive users have in common")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    func logOutButton() -> some View {
        Button {
            showLogOutConfirm = true
        } label: {
            Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
        }
        .padding(.top, 8)
    }
}

#Preview {
    ProfileView(userId: "123")
        .environmentObject(AuthViewModel())
}
