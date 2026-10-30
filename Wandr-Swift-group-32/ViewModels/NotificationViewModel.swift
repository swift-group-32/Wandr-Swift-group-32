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

    init(repository: NotificationRepository) {
        self.repository = repository
    }

    func loadNotifications() async {
        isLoading = true
        errorMessage = nil

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

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
