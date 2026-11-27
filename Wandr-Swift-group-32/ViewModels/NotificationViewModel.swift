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

        do {
            let loadedNotifications = try await repository.fetchNotifications()

            notifications = loadedNotifications

            try await localStorage.save(loadedNotifications)

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

            print("Notifications loaded from Supabase:", loadedNotifications.count)

        } catch {
            if let stored = try? await localStorage.load(), !stored.isEmpty {
                notifications = stored
                print("Using local notifications:", stored.count)
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
    
    func refreshNotifications() async {

        isLoading = true
        errorMessage = nil

        do {
            let loadedNotifications =
                try await repository.fetchNotifications()

            notifications = loadedNotifications

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

            print("Notifications refreshed from Supabase")

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
}
