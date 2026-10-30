//
//  ConnectivityMonitor.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation
import Network
import Combine

@MainActor
final class ConnectivityMonitor: ObservableObject {

    static let shared = ConnectivityMonitor()

    @Published private(set) var isConnected = true

    private let monitor = NWPathMonitor()

    private let queue = DispatchQueue(
        label: "ConnectivityMonitor"
    )

    private init() {

        monitor.pathUpdateHandler = { [weak self] path in

            Task { @MainActor in

                let connected = path.status == .satisfied

                print("Connectivity changed:", connected)

                self?.isConnected = connected
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
