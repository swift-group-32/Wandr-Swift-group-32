import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    let queue = DispatchQueue(label: "Network monitor queue")
    let monitor = NWPathMonitor()

    @Published var isConnected = true

    init() {
        monitor.pathUpdateHandler = { @Sendable path in
            let connected = path.status == .satisfied
            DispatchQueue.main.async {
                self.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }
}
