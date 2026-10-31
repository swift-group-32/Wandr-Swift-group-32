import Foundation
import Testing
@testable import Wandr_Swift_group_32

@MainActor
struct BusinessInsightsTests {
    private final class Service: BusinessInsightsServing {
        var hasAccess = false
        var accessError: Error?
        var activationError: Error?
        var reportError: Error?
        var reportCalls = 0
        var activationCodes: [String] = []

        func hasBusinessAccess() async throws -> Bool {
            if let accessError { throw accessError }
            return hasAccess
        }

        func activate(code: String) async throws {
            activationCodes.append(code)
            if let activationError { throw activationError }
            hasAccess = true
        }

        func fetchReport() async throws -> CategoryEngagementReport {
            reportCalls += 1
            if let reportError { throw reportError }
            return try CategoryEngagementReport.decode(Data(BusinessInsightsTests.reportJSON.utf8))
        }
    }

    @Test func normalUserSeesActivationWithoutRequestingTheReport() async {
        let service = Service()
        let model = BusinessInsightsViewModel(service: service)
        await model.load()
        #expect(model.access == .inactive)
        #expect(model.report == nil)
        #expect(service.reportCalls == 0)
        #expect(!model.isWorking)
    }

    @Test func fourDigitActivationFetchesReportAndClearsCode() async {
        let service = Service()
        let model = BusinessInsightsViewModel(service: service)
        await model.load()
        model.accessCode = " 1234\n"
        await model.activate()
        #expect(service.activationCodes == ["1234"])
        #expect(model.access == .active)
        #expect(model.report?.leaders.first?.category == "park")
        #expect(model.accessCode.isEmpty)
        #expect(model.errorMessage == nil)
    }

    @Test func rejectedActivationDoesNotGrantAccessOrFetchReport() async {
        let service = Service()
        service.activationError = BusinessInsightsError.invalidCode
        let model = BusinessInsightsViewModel(service: service)
        await model.load()
        model.accessCode = "4321"
        await model.activate()
        #expect(model.access == .inactive)
        #expect(service.reportCalls == 0)
        #expect(model.report == nil)
        #expect(model.accessCode == "4321")
        #expect(model.errorMessage?.contains("incorrect") == true)
    }

    @Test func shortCodesAreRejectedBeforeMakingARequest() async {
        let service = Service()
        let model = BusinessInsightsViewModel(service: service)
        model.accessCode = "123"
        await model.activate()
        #expect(service.activationCodes.isEmpty)
        #expect(model.errorMessage != nil)
    }

    @Test func existingBusinessAccountLoadsWithoutReenteringCode() async {
        let service = Service()
        service.hasAccess = true
        let model = BusinessInsightsViewModel(service: service)
        await model.load()
        #expect(model.report != nil)
        #expect(service.activationCodes.isEmpty)
    }

    @Test func failedReportAfterActivationCanRetryWithoutAnotherCode() async {
        let service = Service()
        service.reportError = BusinessInsightsError.offline
        let model = BusinessInsightsViewModel(service: service)
        await model.load()
        model.accessCode = "1234"
        await model.activate()
        #expect(model.access == .active)
        #expect(model.report == nil)
        #expect(model.errorMessage != nil)
        service.reportError = nil
        await model.load()
        #expect(model.report != nil)
        #expect(service.activationCodes == ["1234"])
        #expect(model.errorMessage == nil)
    }

    @Test func revokedAccessClearsPreviouslyVisibleReport() async {
        let service = Service()
        service.hasAccess = true
        let model = BusinessInsightsViewModel(service: service)
        await model.load()
        #expect(model.report != nil)
        // The role can be revoked between reading the profile and requesting the report.
        service.reportError = BusinessInsightsError.accessDenied
        await model.load()
        #expect(model.report == nil)
        #expect(model.access == .inactive)
    }

    @Test func changedProfileFlagAlsoClearsReport() async {
        let service = Service()
        service.hasAccess = true
        let model = BusinessInsightsViewModel(service: service)
        await model.load()
        service.hasAccess = false
        await model.load()
        #expect(model.report == nil)
        #expect(model.access == .inactive)
        #expect(service.reportCalls == 1)
    }

    @Test func expiredSessionDoesNotKeepBusinessDataOnScreen() async {
        let service = Service()
        service.hasAccess = true
        let model = BusinessInsightsViewModel(service: service)
        await model.load()
        service.accessError = BusinessInsightsError.signInRequired
        await model.load()
        #expect(model.report == nil)
        #expect(model.access == .unknown)
    }

    @Test func cancellationDoesNotShowAnErrorOrStayLoading() async {
        let service = Service()
        service.accessError = CancellationError()
        let model = BusinessInsightsViewModel(service: service)
        await model.load()
        #expect(model.errorMessage == nil)
        #expect(!model.isWorking)
    }

    @Test func decodesSupabaseDatesAndRanksByCompletionsThenParticipants() throws {
        let report = try CategoryEngagementReport.decode(Data(Self.reportJSON.utf8))
        #expect(report.windowEnd.timeIntervalSince(report.windowStart) == 30 * 24 * 60 * 60)
        #expect(report.rankedCategories.map(\.category) == ["park", "museum", "restaurant", "other"])
        #expect(report.leaders.map(\.name) == ["Parks"])
        #expect(report.recommendation.contains("3 completed quests from 2 participants"))
        #expect(report.rank(for: report.categories[3]) == nil)
    }

    @Test func equalResultsShareARankAndRecommendation() throws {
        let report = try CategoryEngagementReport.decode(Data(Self.reportJSON.utf8))
        let categories = [
            CategoryEngagement(category: "park", completedQuests: 3, uniqueParticipants: 2),
            CategoryEngagement(category: "museum", completedQuests: 3, uniqueParticipants: 2),
            CategoryEngagement(category: "restaurant", completedQuests: 2, uniqueParticipants: 1)
        ]
        let tied = CategoryEngagementReport(windowStart: report.windowStart, windowEnd: report.windowEnd,
                                            generatedAt: report.generatedAt, categories: categories)
        #expect(tied.leaders.count == 2)
        #expect(tied.rank(for: categories[0]) == 1)
        #expect(tied.rank(for: categories[1]) == 1)
        #expect(tied.rank(for: categories[2]) == 3)
        #expect(tied.recommendation.contains("share the strongest engagement"))
    }

    @Test func zeroActivityDoesNotRecommendACategory() {
        let report = CategoryEngagementReport(windowStart: .now, windowEnd: .now, generatedAt: .now,
            categories: [CategoryEngagement(category: "park", completedQuests: 0, uniqueParticipants: 0)])
        #expect(report.leaders.isEmpty)
        #expect(report.recommendation == "Not enough engagement data to recommend a category yet.")
    }

    static let reportJSON = """
    {"window_start":"2026-10-01T00:00:00.000000Z",
     "window_end":"2026-10-31T00:00:00Z", "generated_at":"2026-10-31T00:00:00.123456Z",
     "categories":[
       {"category":"restaurant","completed_quests":2,"unique_participants":1},
       {"category":"park","completed_quests":3,"unique_participants":2},
       {"category":"museum","completed_quests":2,"unique_participants":2},
       {"category":"other","completed_quests":0,"unique_participants":0}
     ]}
    """
}
