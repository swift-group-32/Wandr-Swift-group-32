import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        Group {
            if auth.isCheckingSession {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.wandrCream.ignoresSafeArea())
            } else if auth.isLoggedIn {
                ContentView()
            } else {
                AuthFlowView()
            }
        }
        .environmentObject(auth)
        .task {
            await auth.checkSession()
        }
    }
}
