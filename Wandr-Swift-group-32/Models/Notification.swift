//
//  Notification.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation

struct AppNotification: Identifiable, Codable {
    let id: UUID
    let type: String
    let content: String?
    let readStatus: Bool
    let createdAt: Date
}
