//
//  SponsoredQuestCache.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation

final class SponsoredQuestCache {

    static let shared = SponsoredQuestCache()

    private let cache = NSCache<NSString, CachedActiveUser>()

    private init() {
        cache.countLimit = 10
    }

    func save(_ user: ActiveUser) {
        let cachedUser = CachedActiveUser(user: user)

        cache.setObject(
            cachedUser,
            forKey: user.userId as NSString
        )

        print("BQ13 result saved in NSCache")
    }

    func load(userId: String) -> ActiveUser? {

        guard let cachedUser = cache.object(
            forKey: userId as NSString
        ) else {
            print("BQ13 result not found in NSCache")
            return nil
        }

        print("BQ13 result loaded from NSCache")
        return cachedUser.user
    }

    func remove(userId: String) {
        cache.removeObject(
            forKey: userId as NSString
        )
    }

    func clear() {
        cache.removeAllObjects()
    }
}

private final class CachedActiveUser {

    let user: ActiveUser

    init(user: ActiveUser) {
        self.user = user
    }
}
