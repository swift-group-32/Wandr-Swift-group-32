import Foundation

protocol RecommendationStrategy {
    func recommend(from quests: [Quest]) -> [Quest]
}
