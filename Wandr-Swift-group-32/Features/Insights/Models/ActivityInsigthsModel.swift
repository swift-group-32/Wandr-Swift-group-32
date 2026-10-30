import Foundation


nonisolated struct UserProfileRow: Codable {
    let user_id: String
    let age_range: String?
    let occupation: String?
    let notifications_enabled: Bool?
}

nonisolated struct UserLastOpenRow: Codable {
    let user_id: String
    let last_opened_epoch: Double?
}

nonisolated struct UserQuestRow: Codable {
    let user_id: String
    let completed_count: Int
    let abandoned_count: Int
    let top_category: String?
}


nonisolated struct InactiveUsersReport: Codable {
    let date: Date
    let totalUsers: Int
    let inactiveUsers: Int

    
    let ageRange: String
    let occupation: String
    let category: String

    
    let notificationsOffInactive: Int
    let notificationsOffActive: Int
    let noQuestsInactive: Int
    let noQuestsActive: Int
    let abandonInactive: Int
    let abandonActive: Int

    
    let avgQuestsInactive: Double
    let avgQuestsActive: Double
}
