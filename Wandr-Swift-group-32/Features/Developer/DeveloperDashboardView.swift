import SwiftUI

struct DeveloperDashboardView: View {
    var body: some View {
        List {
            Section("Analytics") {
                NavigationLink {
                    ActivityInsightsView()
                } label: {
                    Label("Inactive users (BQ9)", systemImage: "chart.bar.xaxis")
                }

                NavigationLink {
                    ReengagementView()
                } label: {
                    Label("Re-engagement", systemImage: "bell.badge")
                }
            }
        }
        .navigationTitle("Developer dashboard")
    }
}

#Preview {
    NavigationStack {
        DeveloperDashboardView()
    }
}

