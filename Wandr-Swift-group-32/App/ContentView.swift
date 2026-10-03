import SwiftUI

struct ContentView: View {

    @State private var selectedTab: AppTab

    init(initialTab: AppTab = .home) {
        _selectedTab = State(initialValue: initialTab)
    }

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
            
            DiscoveryMapView()
                .tabItem { Label("Map", systemImage: "map") }
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
    

}

#Preview {
    ContentView()
}
