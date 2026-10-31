//
//  NotificationViewModel.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {

    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: NotificationRepository
    private let localStorage = NotificationLocalStorage.shared

    init(repository: NotificationRepository) {
        self.repository = repository
    }

    func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        
        var loadedNotifications: [AppNotification] = []
        
        if let cached = await localStorage.loadMemoryCache() {
                    loadedNotifications = cached
                    print("Using memory cache:", cached.count)

                } else if let stored = try? await localStorage.load(),
                          !stored.isEmpty {
                    loadedNotifications = stored
                    print("Using UserDefaults:", stored.count)

                } else {
                    do {
                        loadedNotifications = try await repository.fetchNotifications()
                        print("Loaded from Supabase:", loadedNotifications.count)
                    } catch {
                        errorMessage = error.localizedDescription
                        isLoading = false
                        return
                    }
                }

                notifications = loadedNotifications

                do {
                    try await repository.markAllAsRead()

                    notifications = loadedNotifications.map { notification in
                        AppNotification(
                            id: notification.id,
                            type: notification.type,
                            content: notification.content,
                            readStatus: true,
                            createdAt: notification.createdAt
                        )
                    }

                    try await localStorage.save(notifications)

                    print("Notifications marked as read and cache updated")


        } catch {
            print("Could not mark notifications as read:", error.localizedDescription)
        }

        isLoading = false
    }
    
}
