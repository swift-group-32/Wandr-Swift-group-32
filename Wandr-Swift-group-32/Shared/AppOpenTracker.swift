import Foundation
import Supabase


struct AppOpenTracker {

    static let pendingKey = "pendingAppOpen"

    static func appOpened() async {
        if NetworkMonitor.shared.isConnected {
            do {
                try await supabase.rpc("touch_last_opened").execute()
                UserDefaults.standard.set(false, forKey: pendingKey)
            } catch {
                UserDefaults.standard.set(true, forKey: pendingKey)
            }
        } else {
            UserDefaults.standard.set(true, forKey: pendingKey)
        }
    }

    static func sendPendingOpen() async {
        if UserDefaults.standard.bool(forKey: pendingKey) {
            await appOpened()
        }
    }
}
