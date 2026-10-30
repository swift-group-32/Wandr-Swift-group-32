//
//  SponsoredQuestLocalStorage.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation

actor SponsoredQuestLocalStorage {

    static let shared = SponsoredQuestLocalStorage()

    private let key = "bq13_cached_active_user"

    func save(_ user: ActiveUser) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)

        UserDefaults.standard.set(
            data,
            forKey: key
        )

        print("BQ13 result saved to UserDefaults")
    }

    func load() throws -> ActiveUser? {

        guard let data = UserDefaults.standard.data(
            forKey: key
        ) else {
            print("No BQ13 data in UserDefaults")
            return nil
        }

        let decoder = JSONDecoder()

        let user = try decoder.decode(
            ActiveUser.self,
            from: data
        )

        print("BQ13 result loaded from UserDefaults")

        return user
    }

    func clear() {
        UserDefaults.standard.removeObject(
            forKey: key
        )
    }
}
