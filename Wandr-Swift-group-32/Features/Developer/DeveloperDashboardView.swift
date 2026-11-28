import SwiftUI

struct DeveloperDashboardView: View {
    var body: some View {
        List {
            Section("Analytics") {
                NavigationLink {
                    LowUseCategoriesView()
                } label: {
                    Label("Categorías de bajo uso (BQ7)", systemImage: "chart.bar")
                }

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

