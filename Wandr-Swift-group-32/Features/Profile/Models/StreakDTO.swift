
//Endpoint GET /users/{userId}/streak
import Foundation

struct StreakDTO: Codable{
    let userId: String
    let stats: UserStats
    let streak: StreakInfo
    let achievements: [Achievement]
}

struct UserStats: Codable{
    let questsCompleted: Int
    let points: Int
}

struct StreakInfo: Codable{
    let currentStreak: Int
    let thisWeek: [Bool]
    let weeklyHistory: [WeekData]
}

struct WeekData: Codable, Identifiable{
    let weekId: String
    let quests: Int
    var id: String {weekId}
}

struct Achievement: Codable, Identifiable {
    let id: String
    let name: String
    let unlocked: Bool
}

//Mockup Data
extension StreakDTO {
    static let mock = StreakDTO(
        userId: "123",
        stats: UserStats(
            questsCompleted: 47,
            points: 850
        ),
        streak: StreakInfo(
            currentStreak: 14,
            thisWeek: [true, true, true, true, true, true, false],
            weeklyHistory: [
                WeekData(weekId: "W1", quests: 2),
                WeekData(weekId: "W2", quests: 3),
                WeekData(weekId: "W3", quests: 3),
                WeekData(weekId: "W4", quests: 5)
            ]
        ),
        achievements: [
            Achievement(id: "1", name: "First Foot", unlocked: true),
            Achievement(id: "2", name: "Two-Weeker", unlocked: true),
            Achievement(id: "3", name: "Peak Climber", unlocked: false)
        ]
    )
}
