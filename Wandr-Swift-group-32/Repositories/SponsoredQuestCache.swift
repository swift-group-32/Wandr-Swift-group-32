//
//  SponsoredQuestCache.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation

final class SponsoredQuestCache {

    static let shared = SponsoredQuestCache()

    private let cache =
        NSCache<NSString, CachedSponsoredQuest>()

    private init() {
        cache.countLimit = 20
    }

    func save(_ user: ActiveUser) {

        let cachedUser = CachedSponsoredQuest(
            user: user
        )

        cache.setObject(
            cachedUser,
            forKey: "user-\(user.userId)" as NSString
        )

        for sponsoredQuest in user.sponsoredQuests {

            let cachedQuest = CachedSponsoredQuest(
                quest: sponsoredQuest
            )

            cache.setObject(
                cachedQuest,
                forKey: "quest-\(sponsoredQuest.id.uuidString)" as NSString
            )
        }

        print("BQ13 data saved in NSCache")
    }

    func loadUser(userId: String) -> ActiveUser? {

        guard let cachedObject =
                cache.object(
                    forKey: "user-\(userId)" as NSString
                )
        else {
            return nil
        }

        return cachedObject.user
    }

    func loadSponsoredQuest(
        questId: UUID
    ) -> SponsoredQuest? {

        guard let cachedObject =
                cache.object(
                    forKey: "quest-\(questId.uuidString)" as NSString
                )
        else {
            return nil
        }

        return cachedObject.quest
    }

    func remove(userId: String) {

        cache.removeObject(
            forKey: "user-\(userId)" as NSString
        )
    }

    func clear() {

        cache.removeAllObjects()
    }
}

private final class CachedSponsoredQuest {

    let user: ActiveUser?
    let quest: SponsoredQuest?

    init(user: ActiveUser) {
        self.user = user
        self.quest = nil
    }

    init(quest: SponsoredQuest) {
        self.user = nil
        self.quest = quest
    }
}
