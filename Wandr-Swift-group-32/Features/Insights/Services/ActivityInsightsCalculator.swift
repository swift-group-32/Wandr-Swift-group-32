import Foundation

nonisolated struct ActivityInsightsCalculator {

    static func makeReport(profiles: [UserProfileRow],
                           lastOpens: [UserLastOpenRow],
                           quests: [UserQuestRow],
                           now: Date = Date()) -> InactiveUsersReport {

        let twoWeeksAgo = now.timeIntervalSince1970 - 14 * 24 * 60 * 60

        
        var lastOpenByUser: [String: Double] = [:]
        for row in lastOpens {
            if let lastOpen = row.last_opened_epoch {
                lastOpenByUser[row.user_id] = lastOpen
            }
        }

        var questsByUser: [String: UserQuestRow] = [:]
        for row in quests {
            questsByUser[row.user_id] = row
        }

        
        var inactive: [UserProfileRow] = []
        var active: [UserProfileRow] = []
        for profile in profiles {
            if let lastOpen = lastOpenByUser[profile.user_id], lastOpen >= twoWeeksAgo {
                active.append(profile)
            } else {
                inactive.append(profile)
            }
        }

        func completed(_ user: UserProfileRow) -> Int {
            questsByUser[user.user_id]?.completed_count ?? 0
        }

        func abandoned(_ user: UserProfileRow) -> Int {
            questsByUser[user.user_id]?.abandoned_count ?? 0
        }

        return InactiveUsersReport(
            date: now,
            totalUsers: profiles.count,
            inactiveUsers: inactive.count,
            ageRange: mostCommon(inactive.map { $0.age_range }),
            occupation: mostCommon(inactive.map { $0.occupation }),
            category: mostCommon(inactive.map { questsByUser[$0.user_id]?.top_category }),
            notificationsOffInactive: percent(inactive.filter { $0.notifications_enabled == false }.count, of: inactive.count),
            notificationsOffActive: percent(active.filter { $0.notifications_enabled == false }.count, of: active.count),
            noQuestsInactive: percent(inactive.filter { completed($0) == 0 }.count, of: inactive.count),
            noQuestsActive: percent(active.filter { completed($0) == 0 }.count, of: active.count),
            abandonInactive: percent(inactive.filter { abandoned($0) > completed($0) }.count, of: inactive.count),
            abandonActive: percent(active.filter { abandoned($0) > completed($0) }.count, of: active.count),
            avgQuestsInactive: average(inactive.map { completed($0) }),
            avgQuestsActive: average(active.map { completed($0) })
        )
    }

    
    static func mostCommon(_ values: [String?]) -> String {
        var counts: [String: Int] = [:]
        for value in values {
            // Skip empty answers and "Prefer not to say"
            if let value = value, value != "prefer_not_to_say" {
                counts[value, default: 0] += 1
            }
        }
        let sorted = counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
        guard let first = sorted.first?.key else { return "No data" }
        return first.replacingOccurrences(of: "_", with: " ").capitalized
    }

    static func percent(_ count: Int, of total: Int) -> Int {
        if total == 0 { return 0 }
        return Int((Double(count) / Double(total) * 100).rounded())
    }

    static func average(_ numbers: [Int]) -> Double {
        if numbers.isEmpty { return 0 }
        return Double(numbers.reduce(0, +)) / Double(numbers.count)
    }
}
