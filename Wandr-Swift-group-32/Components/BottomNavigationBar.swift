import SwiftUI

enum AppTab {
    case home
    case explore
    case map
    case saved
    case profile
    case mysteryQuest
}

struct BottomNavigationBar: View {
    
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack {
            
            navigationItem(
                icon: "house",
                title: "Home",
                tab: .home
            )
            
            Spacer()
            
            navigationItem(
                icon: "safari",
                title: "Explore",
                tab: .explore
            )
            
            Spacer()
            
            navigationItem(
                icon: "map",
                title: "Map",
                tab: .map
            )
            
            Spacer()
            
            navigationItem(
                icon: "bookmark",
                title: "Saved",
                tab: .saved
            )
            
            Spacer()
            
            navigationItem(
                icon: "person",
                title: "Profile",
                tab: .profile
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
    
    @ViewBuilder
    private func navigationItem(
        icon: String,
        title: String,
        tab: AppTab
    ) -> some View {
        
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(
                selectedTab == tab
                ? Color("WandrPrimary")
                : Color.secondary
            )
            .frame(maxWidth: .infinity)
        }
    }
}
