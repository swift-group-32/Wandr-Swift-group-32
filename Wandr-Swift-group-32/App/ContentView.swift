

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ActiveQuestView()
                .tabItem {
                    Label("Quest", systemImage: "flag")
                }

            ProfileView(userId: "123")
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(.wandrGreen)
    }
}

#Preview {
    ContentView()
}
