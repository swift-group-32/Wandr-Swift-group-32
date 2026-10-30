import Foundation
import Combine

class ActivityInsightsViewModel: ObservableObject {

    @Published var report: InactiveUsersReport? = nil
    @Published var isLoading = false
    @Published var message: String? = nil

    let repository = ActivityInsightsRepository()
    let network = NetworkMonitor.shared
    var cancellables = Set<AnyCancellable>()

    init() {
        
        network.$isConnected
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] connected in
                guard let self = self else { return }
                if connected {
                    // Internet is back: load new data
                    Task { await self.loadFromNetwork() }
                } else {
                    self.isLoading = false
                    self.message = self.offlineMessage()
                }
            }
            .store(in: &cancellables)
    }

    func load() async {
        
        if let cached = ActivityInsightsCache.shared.get() {
            report = cached
            if ActivityInsightsCache.shared.isFresh() {
                return
            }
        }

        if report == nil, let saved = ActivityInsightsStorage.load() {
            report = saved
            ActivityInsightsCache.shared.save(saved)
        }

        if network.isConnected {
            await loadFromNetwork()
        } else {
            message = offlineMessage()
        }
    }

    func loadFromNetwork() async {
        if !network.isConnected {
            message = offlineMessage()
            return
        }

        isLoading = true
        message = nil

        let slowTimer = Task {
            try? await Task.sleep(for: .seconds(5))
            if isLoading && !Task.isCancelled {
                message = "Slow connection. Showing the saved analysis while the new one loads..."
            }
        }

        do {
            async let profiles = repository.fetchProfiles()
            async let lastOpens = repository.fetchLastOpens()
            async let quests = repository.fetchQuestHistory()
            let (profileRows, lastOpenRows, questRows) = try await (profiles, lastOpens, quests)

            slowTimer.cancel()
            calculateInBackground(profiles: profileRows, lastOpens: lastOpenRows, quests: questRows)
        } catch {
            print("BQ9 error:", error)
            slowTimer.cancel()
            isLoading = false
            if network.isConnected {
                message = "Could not update the analysis. Pull down to try again."
            } else {
                message = offlineMessage()
            }
        }
    }

    func calculateInBackground(profiles: [UserProfileRow], lastOpens: [UserLastOpenRow], quests: [UserQuestRow]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let newReport = ActivityInsightsCalculator.makeReport(profiles: profiles, lastOpens: lastOpens, quests: quests)

            ActivityInsightsStorage.save(newReport)

            DispatchQueue.main.async {
                self.report = newReport
                ActivityInsightsCache.shared.save(newReport)
                self.isLoading = false
                self.message = nil
            }
        }
    }

    func offlineMessage() -> String {
        if let report = report {
            let date = report.date.formatted(date: .abbreviated, time: .shortened)
            return "You're offline. Showing the analysis saved on \(date). It will update when the internet comes back."
        }
        return "You're offline and there is no saved analysis yet. Connect to the internet to load it."
    }
}
