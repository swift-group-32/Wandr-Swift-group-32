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
        
        if let cached = await localStorage.loadMemoryCache() {
            notifications = cached
            isLoading = false
            print("Using memory cache:", cached.count)
            return
        }
        
        if let stored = try? await localStorage.load(),
           !stored.isEmpty {
            notifications = stored
            isLoading = false
            print("Using UserDefaults:", stored.count)
            return
        }

        do {
            notifications = try await repository.fetchNotifications()

            try await repository.markAllAsRead()

            notifications = notifications.map { notification in
                AppNotification(
                    id: notification.id,
                    type: notification.type,
                    content: notification.content,
                    readStatus: true,
                    createdAt: notification.createdAt
                )
            }
            
            try await localStorage.save(notifications)

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
}
