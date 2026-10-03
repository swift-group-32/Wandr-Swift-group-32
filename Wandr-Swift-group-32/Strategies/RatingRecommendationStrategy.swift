import Foundation

struct RatingRecommendationStrategy: RecommendationStrategy {
    
    func recommend(from quests: [Quest]) -> [Quest] {
        quests.sorted {
            $0.rating > $1.rating
        }
    }
}
