//
//  NotificationRepository.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation
import Supabase

protocol NotificationRepository {
    func fetchNotifications() async throws -> [AppNotification]
    func markAllAsRead() async throws
}

final class SupabaseNotificationRepository: NotificationRepository {

    private let supabase = SupabaseManager.shared.client

    func fetchNotifications() async throws -> [AppNotification] {

        let userId = try await supabase.auth.session.user.id

        let response = try await supabase
            .from("notifications")
            .select("id, type, content, read_status, created_at")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()

            formatter.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds
            ]

            if let date = formatter.date(from: value) {
                return date
            }

            formatter.formatOptions = [
                .withInternetDateTime
            ]

            if let date = formatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(value)"
            )
        }

        return try decoder.decode(
            [AppNotification].self,
            from: response.data
        )
    }

    func markAllAsRead() async throws {

        let userId = try await supabase.auth.session.user.id

        try await supabase
            .from("notifications")
            .update([
                "read_status": true
            ])
            .eq("user_id", value: userId)
            .eq("read_status", value: false)
            .execute()
    }
}
