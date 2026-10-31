import Foundation
import Combine

@MainActor
final class BusinessInsightsViewModel: ObservableObject {
    enum Access { case unknown, inactive, active }

    @Published private(set) var access: Access = .unknown
    @Published private(set) var report: CategoryEngagementReport?
    @Published private(set) var isWorking = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var notice: String?
    @Published var accessCode = ""

    private let service: any BusinessInsightsServing
    private let storage: BusinessInsightsStorage
    private var accountID: String?
    private var isVisible = false
    private var isConnected = true
    private var pendingReconnect = false

    init(service: (any BusinessInsightsServing)? = nil, storage: BusinessInsightsStorage? = nil) {
        self.service = service ?? BusinessInsightsService()
        self.storage = storage ?? .shared
    }

    func appear(isConnected: Bool) async {
        isVisible = true
        await load(isConnected: isConnected)
    }

    func disappear() {
        isVisible = false
        pendingReconnect = false
    }

    func connectivityChanged(isConnected: Bool) async {
        self.isConnected = isConnected
        guard isVisible else { return }
        if !isConnected {
            notice = offlineNotice
        } else if isWorking {
            pendingReconnect = true
        } else {
            await load(forceRefresh: true, isConnected: true)
        }
    }

    func load(forceRefresh: Bool = false, isConnected: Bool = true) async {
        guard !isWorking else { return }
        self.isConnected = isConnected
        errorMessage = nil
        notice = nil
        guard let id = service.currentAccountID else {
            report = nil
            access = .unknown
            errorMessage = "Please log in again to access Business Insights."
            return
        }
        if accountID != id {
            report = nil
            access = .unknown
            accessCode = ""
            accountID = id
        }
        if report == nil, let saved = try? storage.load(accountID: id) {
            report = saved
            access = .active
        }
        guard isConnected else {
            notice = offlineNotice
            return
        }
        if !forceRefresh && report != nil && storage.isFresh(accountID: id) { return }
        if report != nil { notice = savedNotice }

        isWorking = true
        let generation = storage.generation
        defer { finishRequest() }
        do {
            let allowed = try await service.hasBusinessAccess()
            guard requestIsCurrent(id: id, generation: generation) else { return }
            access = allowed ? .active : .inactive
            guard allowed else {
                discardReport(id: id)
                return
            }
            let freshReport = try await service.fetchReport()
            guard requestIsCurrent(id: id, generation: generation) else { return }
            accept(freshReport, id: id)
        } catch {
            guard requestIsCurrent(id: id, generation: generation) else { return }
            handle(error, id: id)
        }
    }

    func activate(isConnected: Bool = true) async {
        guard !isWorking else { return }
        self.isConnected = isConnected
        guard isConnected else {
            errorMessage = "Connect to the internet to activate business access."
            return
        }
        guard let id = service.currentAccountID else {
            report = nil
            access = .unknown
            errorMessage = "Please log in again to activate business access."
            return
        }
        let code = accessCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (4...128).contains(code.count) else {
            errorMessage = "Enter a business access code between 4 and 128 characters."
            return
        }
        accountID = id
        isWorking = true
        errorMessage = nil
        notice = nil
        let generation = storage.generation
        defer { finishRequest() }
        do {
            try await service.activate(code: code)
            guard requestIsCurrent(id: id, generation: generation) else { return }
            accessCode = ""
            access = .active
            let freshReport = try await service.fetchReport()
            guard requestIsCurrent(id: id, generation: generation) else { return }
            accept(freshReport, id: id)
        } catch {
            guard requestIsCurrent(id: id, generation: generation) else { return }
            handle(error, id: id)
        }
    }

    private func accept(_ freshReport: CategoryEngagementReport, id: String) {
        report = freshReport
        notice = isConnected ? nil : offlineNotice
        do {
            try storage.save(freshReport, accountID: id)
        } catch {
            notice = "Report loaded, but it could not be saved for offline use."
        }
    }

    private func discardReport(id: String) {
        report = nil
        notice = nil
        do { try storage.remove(accountID: id) }
        catch { print("Could not remove saved business report:", error) }
    }

    private func requestIsCurrent(id: String, generation: Int) -> Bool {
        guard service.currentAccountID == id, storage.generation == generation else {
            report = nil
            access = .unknown
            pendingReconnect = false
            return false
        }
        return !Task.isCancelled
    }

    private func finishRequest() {
        isWorking = false
        // One retry if the connection returned while the previous request was finishing.
        let shouldRefresh = pendingReconnect && isVisible && isConnected
        pendingReconnect = false
        if shouldRefresh {
            Task { [weak self] in
                guard let self, self.isVisible, self.isConnected else { return }
                await self.load(forceRefresh: true, isConnected: true)
            }
        }
    }

    private var savedNotice: String? {
        report.map { "Showing saved report from \($0.generatedAt.formatted(date: .abbreviated, time: .shortened))." }
    }

    private var offlineNotice: String {
        if let savedNotice { return "You're offline. " + savedNotice }
        if access == .inactive { return "Connect to activate business access." }
        return "You're offline and there is no saved report for this account. Connect to load sponsorship insights."
    }

    private func handle(_ error: Error, id: String) {
        if error is CancellationError || (error as? URLError)?.code == .cancelled { return }
        switch error as? BusinessInsightsError {
        case .invalidCode:
            errorMessage = "That access code is incorrect. Try again."
        case .accessDenied:
            discardReport(id: id)
            access = .inactive
            errorMessage = "Business access is required to view this report."
        case .signInRequired:
            discardReport(id: id)
            access = .unknown
            errorMessage = "Please log in again to access Business Insights."
        case .offline:
            notice = savedNotice
            errorMessage = "Could not connect. Check your internet connection and try again."
        default:
            notice = savedNotice
            errorMessage = "Could not load Business Insights. Please try again."
        }
    }
}
