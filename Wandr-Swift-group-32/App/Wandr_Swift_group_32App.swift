
import SwiftUI

@main
struct Wandr_Swift_group_32App: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-rating-review") {
                NavigationStack { RatingReviewView(context: .preview) }
            } else if ProcessInfo.processInfo.arguments.contains("--open-map") {
                ContentView(initialTab: .map)
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
    }
}
