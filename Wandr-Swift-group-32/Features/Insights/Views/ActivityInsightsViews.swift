import SwiftUI


struct ActivityInsightsView: View {
    @StateObject private var viewModel = ActivityInsightsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let message = viewModel.message {
                    messageBanner(message)
                }

                if let report = viewModel.report {
                    summaryCard(report)
                    commonCard(report)
                    compareCard(report)
                    Text("Updated \(report.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                } else if viewModel.isLoading {
                    ProgressView("Analyzing users...")
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .background(Color.wandrCream)
        .navigationTitle("Inactive users")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadFromNetwork()
        }
        .task {
            await viewModel.load()
        }
    }

    func messageBanner(_ text: String) -> some View {
        HStack {
            Image(systemName: NetworkMonitor.shared.isConnected ? "exclamationmark.triangle" : "wifi.slash")
                .foregroundColor(.orange)
            Text(text)
                .font(.caption)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
    }

    
    func summaryCard(_ report: InactiveUsersReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOT OPENED IN 2 WEEKS")
                .font(.caption2)
                .foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline) {
                Text("\(report.inactiveUsers)")
                    .font(.largeTitle).bold()
                    .foregroundColor(.wandrGreen)
                Text("of \(report.totalUsers) users")
                    .foregroundColor(.gray)
            }
            ProgressView(value: Double(report.inactiveUsers), total: Double(max(report.totalUsers, 1)))
                .tint(.wandrGreen)
        }
        .cardStyle()
    }

    
    func commonCard(_ report: InactiveUsersReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT THEY HAVE IN COMMON")
                .font(.caption2)
                .foregroundColor(.gray)
            row("Age range", report.ageRange, icon: "person.2")
            row("Occupation", report.occupation, icon: "briefcase")
            row("Favorite category", report.category, icon: "square.grid.2x2")
        }
        .cardStyle()
    }

    
    func compareCard(_ report: InactiveUsersReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("INACTIVE VS ACTIVE")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text("Inactive").font(.caption).bold().foregroundColor(.wandrGreen)
                    .frame(width: 55, alignment: .trailing)
                Text("Active").font(.caption).bold().foregroundColor(.wandrSand)
                    .frame(width: 45, alignment: .trailing)
            }
            compareRow("Notifications off", "\(report.notificationsOffInactive)%", "\(report.notificationsOffActive)%")
            compareRow("Never finished a quest", "\(report.noQuestsInactive)%", "\(report.noQuestsActive)%")
            compareRow("Abandon more than finish", "\(report.abandonInactive)%", "\(report.abandonActive)%")
            compareRow("Avg. quests completed",
                       String(format: "%.1f", report.avgQuestsInactive),
                       String(format: "%.1f", report.avgQuestsActive))
        }
        .cardStyle()
    }

    func row(_ title: String, _ value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.wandrGreen)
            Spacer()
            Text(value)
                .font(.subheadline).bold()
        }
    }

    func compareRow(_ title: String, _ inactive: String, _ active: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(inactive)
                .font(.subheadline).bold()
                .foregroundColor(.wandrGreen)
                .frame(width: 55, alignment: .trailing)
            Text(active)
                .font(.subheadline).bold()
                .foregroundColor(.wandrSand)
                .frame(width: 45, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationStack {
        ActivityInsightsView()
    }
}
