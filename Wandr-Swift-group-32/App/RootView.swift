import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var network = NetworkMonitor.shared

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
        
        .onChange(of: auth.isLoggedIn) { _, loggedIn in
            if loggedIn { recordAppOpen() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && auth.isLoggedIn { recordAppOpen() }
        }

        .onChange(of: network.isConnected) { _, connected in
            if connected && auth.isLoggedIn {
                Task { await AppOpenTracker.sendPendingOpen() }
            }
        }
    }

    func recordAppOpen() {
        Task { await AppOpenTracker.appOpened() }
    }
}
