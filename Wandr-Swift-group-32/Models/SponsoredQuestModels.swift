//
//  SponsoredQuestModels.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 29/10/26.
//

import Foundation

struct ActiveUser: Codable  {
    let userId: String
    let name: String
    let completedQuests: Int
    let hasTriedSponsoredQuest: Bool
    let sponsoredQuest: SponsoredQuest?
}

struct SponsoredQuest: Codable {
    let id: UUID
    let title: String
    let description: String
    let sponsorName: String
    let duration: Int
    let rating: Double
    let category: String
}

