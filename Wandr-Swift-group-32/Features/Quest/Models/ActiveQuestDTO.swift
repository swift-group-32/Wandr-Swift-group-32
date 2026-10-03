import Foundation

struct StartableQuestDTO: Decodable, Identifiable {
    let id: String
    let title: String
    let estimatedDuration: Int?
    let place: StartableQuestPlace
}

struct StartableQuestPlace: Decodable {
    let name: String
}

struct ActiveQuestDTO: Codable {
    let id: String
    let questId: String
    let status: String
    let quest: QuestInfo
    let checked: [CheckedObjective]
}

struct QuestInfo: Codable {
    let title: String
    let place: PlaceInfo
    let objectives: [QuestObjective]
}

struct PlaceInfo: Codable {
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
}

struct QuestObjective: Codable, Identifiable {
    let id: String
    let title: String
    let requiresPhoto: Bool
    let orderIndex: Int
}

struct CheckedObjective: Codable {
    let objectiveId: String
}

// Mock data 
extension ActiveQuestDTO {
    
    static let mock = ActiveQuestDTO(
        id: "c1",
        questId: "q1",
        status: "pending",
        quest: QuestInfo(
            title: "Catch a live set",
            place: PlaceInfo(
                name: "Festival Jazz al Parque",
                address: "Parque El Country, Bogota",
                latitude: 4.6870,
                longitude: -74.0470
            ),
            objectives: [
                QuestObjective(id: "o1", title: "Arrive at Parque El Country", requiresPhoto: false, orderIndex: 1),
                QuestObjective(id: "o2", title: "Watch a full performance", requiresPhoto: false, orderIndex: 2),
                QuestObjective(id: "o3", title: "Take a photo of the stage", requiresPhoto: true, orderIndex: 3)
            ]
        ),
        checked: [
            CheckedObjective(objectiveId: "o1"),
            CheckedObjective(objectiveId: "o2")
        ]
        
    )
}

struct ObjectiveResult: Codable {
let questCompleted: Bool
let xpEarned: Int
}
