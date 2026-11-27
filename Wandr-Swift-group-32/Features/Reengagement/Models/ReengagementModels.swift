import Foundation

struct ReengagementRecommendation: Identifiable, Codable, Sendable {
    let id: UUID
    let userId: UUID
    let userName: String
    let activityDropPercentage: Double
    let preferredCategory: String

    let recommendedQuestId: UUID
    let recommendedQuestTitle: String
    let recommendedQuestDescription: String
    let sponsorName: String

    let sponsoredQuestCategory: String
    let matchesPreferredCategory: Bool
    let matchesPreviousCategory: Bool
    let reengagementLikelihood: Double

    let generatedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        userName: String,
        activityDropPercentage: Double,
        preferredCategory: String,
        recommendedQuestId: UUID,
        recommendedQuestTitle: String,
        recommendedQuestDescription: String,
        sponsorName: String,
        sponsoredQuestCategory: String,
        matchesPreferredCategory: Bool,
        matchesPreviousCategory: Bool,
        reengagementLikelihood: Double,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.activityDropPercentage = activityDropPercentage
        self.preferredCategory = preferredCategory
        self.recommendedQuestId = recommendedQuestId
        self.recommendedQuestTitle = recommendedQuestTitle
        self.recommendedQuestDescription = recommendedQuestDescription
        self.sponsorName = sponsorName
        self.sponsoredQuestCategory = sponsoredQuestCategory
        self.matchesPreferredCategory = matchesPreferredCategory
        self.matchesPreviousCategory = matchesPreviousCategory
        self.reengagementLikelihood = reengagementLikelihood
        self.generatedAt = generatedAt
    }
}

struct ReengagementInsightsReport: Codable, Sendable {
    let generatedAt: Date
    let recommendations: [ReengagementRecommendation]
}
