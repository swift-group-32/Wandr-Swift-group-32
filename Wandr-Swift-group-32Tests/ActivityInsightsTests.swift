import Testing
import Foundation
@testable import Wandr_Swift_group_32

struct ActivityInsightsTests {

    let now = Date()
    let day: Double = 24 * 60 * 60

    @Test func findsWhatInactiveUsersHaveInCommon() {
        let profiles = [
            UserProfileRow(user_id: "a", age_range: "18-24", occupation: "student",
                           notifications_enabled: false),
            UserProfileRow(user_id: "b", age_range: "18-24", occupation: "student",
                           notifications_enabled: false),
            UserProfileRow(user_id: "c", age_range: "25-34", occupation: "employee",
                           notifications_enabled: true)
        ]
        let lastOpens = [
            UserLastOpenRow(user_id: "a", last_opened_epoch: now.timeIntervalSince1970 - 20 * day),
            UserLastOpenRow(user_id: "b", last_opened_epoch: nil),
            UserLastOpenRow(user_id: "c", last_opened_epoch: now.timeIntervalSince1970 - 1 * day)
        ]
        let quests = [
            UserQuestRow(user_id: "c", completed_count: 4, abandoned_count: 0, top_category: "food")
        ]

        let report = ActivityInsightsCalculator.makeReport(profiles: profiles, lastOpens: lastOpens,
                                                           quests: quests, now: now)

        #expect(report.totalUsers == 3)
        #expect(report.inactiveUsers == 2)
        #expect(report.ageRange == "18-24")
        #expect(report.occupation == "Student")
        #expect(report.notificationsOffInactive == 100)
        #expect(report.notificationsOffActive == 0)
        #expect(report.noQuestsInactive == 100)
        #expect(report.avgQuestsActive == 4)
    }

    @Test func emptyListsDoNotCrash() {
        let report = ActivityInsightsCalculator.makeReport(profiles: [], lastOpens: [], quests: [])
        #expect(report.totalUsers == 0)
        #expect(report.ageRange == "No data")
    }

    @Test func savesAndLoadsTheReportFromTheFile() {
        let report = ActivityInsightsCalculator.makeReport(profiles: [], lastOpens: [], quests: [])
        ActivityInsightsStorage.save(report)
        #expect(ActivityInsightsStorage.load()?.totalUsers == 0)
    }
}
