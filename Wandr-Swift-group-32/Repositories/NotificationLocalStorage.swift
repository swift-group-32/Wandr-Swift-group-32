//
//  NotificationLocalStorage.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation

actor NotificationLocalStorage {
    static let shared = NotificationLocalStorage()

    private let key = "cached_notifications"
    private var memoryCache: [AppNotification]?

    func save(_ notifications: [AppNotification]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(notifications)

        UserDefaults.standard.set(
            data,
            forKey: key
        )
        
        memoryCache = notifications
        print("Notifications saved to memory cache:", notifications.count)
    }

    func load() throws -> [AppNotification] {
        if let memoryCache {
            print(" Loaded from memory cache:", memoryCache.count)
            return memoryCache
        }
        
        guard let data = UserDefaults.standard.data(
            forKey: key
        ) else {
            print("No data in UserDefaults")
            return []
        }
        
        print(" Loaded from UserDefaults")

        let decoder = JSONDecoder()

        let notifications = try decoder.decode(
            [AppNotification].self,
            from: data
        )

        memoryCache = notifications

        return notifications
    }
    
    func loadMemoryCache() -> [AppNotification]? {
        return memoryCache
    }

    
}
