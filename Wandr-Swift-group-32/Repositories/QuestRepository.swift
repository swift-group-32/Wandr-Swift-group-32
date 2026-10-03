import Foundation

protocol QuestRepository {
    func getPersonalizedQuests(userId: String) async throws -> [Quest]
}
