import Foundation
import Combine

@MainActor
final class BusinessInsightsViewModel: ObservableObject {
    enum Access { case unknown, inactive, active }

    @Published private(set) var access: Access = .unknown
    @Published private(set) var report: CategoryEngagementReport?
    @Published private(set) var isWorking = false
    @Published private(set) var errorMessage: String?
    @Published var accessCode = ""

    private let service: any BusinessInsightsServing

    init(service: (any BusinessInsightsServing)? = nil) {
        self.service = service ?? BusinessInsightsService()
    }

    func load() async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            let allowed = try await service.hasBusinessAccess()
            try Task.checkCancellation()
            access = allowed ? .active : .inactive
            guard allowed else {
                report = nil
                return
            }
            let freshReport = try await service.fetchReport()
            try Task.checkCancellation()
            report = freshReport
        } catch {
            handle(error)
        }
    }

    func activate() async {
        guard !isWorking else { return }
        let code = accessCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (4...128).contains(code.count) else {
            errorMessage = "Enter a business access code between 4 and 128 characters."
            return
        }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await service.activate(code: code)
            try Task.checkCancellation()
            accessCode = ""
            access = .active
            let freshReport = try await service.fetchReport()
            try Task.checkCancellation()
            report = freshReport
        } catch {
            handle(error)
        }
    }

    private func handle(_ error: Error) {
        if error is CancellationError || (error as? URLError)?.code == .cancelled { return }
        switch error as? BusinessInsightsError {
        case .invalidCode:
            errorMessage = "That access code is incorrect. Try again."
        case .accessDenied:
            report = nil
            access = .inactive
            errorMessage = "Business access is required to view this report."
        case .signInRequired:
            report = nil
            access = .unknown
            errorMessage = "Please log in again to access Business Insights."
        case .offline:
            errorMessage = "Could not connect. Check your internet connection and try again."
        default:
            errorMessage = "Could not load Business Insights. Please try again."
        }
    }
}
