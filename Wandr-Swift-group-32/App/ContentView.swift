import SwiftUI

struct ContentView: View {

    @State private var selectedTab: AppTab = .home

    var body: some View {

        TabView(selection: $selectedTab) {

            HomeView(selectedTab: $selectedTab)
            .tabItem {
                Label(
                    "Home",
                    systemImage: "house"
                )
            }
            .tag(AppTab.home)

            ExploreView(
                selectedTab: $selectedTab,
                savedQuestIds: .constant([]),
                savedEventIds: .constant([]),
                selectedCategory: .constant("All")
            )
            .tabItem {
                Label(
                    "Explore",
                    systemImage: "safari"
                )
            }
            .tag(AppTab.explore)
            
            placeholderView(
                            title: "Map",
                            icon: "map"
                        )
                        .tabItem {
                            Label(
                                "Map",
                                systemImage: "map"
                            )
                        }
                        .tag(AppTab.map)

            ActiveQuestView()
                .tabItem {
                    Label(
                        "Quest",
                        systemImage: "flag"
                    )
                }
                .tag(AppTab.quest)

            ProfileView(
                userId: "123"
            )
            .tabItem {
                Label(
                    "Profile",
                    systemImage: "person"
                )
            }
            .tag(AppTab.profile)
        }
        .tint(.wandrGreen)
    }
    
    @ViewBuilder
        private func placeholderView(
            title: String,
            icon: String
        ) -> some View {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 50))

                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color("WandrPrimary"))
        }
}

#Preview {
    ContentView()
}
