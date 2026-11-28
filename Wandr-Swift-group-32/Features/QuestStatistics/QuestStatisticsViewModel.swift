import Combine
import Foundation

@MainActor
final class QuestStatisticsStore {
    static let shared = QuestStatisticsStore()

    private static let lifetime: TimeInterval = 300
    private let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first?.appendingPathComponent("QuestStatistics", isDirectory: true)
    private var memory: [UUID: QuestStatistics] = [:]
    private(set) var revision = UUID()

    func cached(for account: UUID, now: Date = .now) -> QuestStatistics? {
        guard let report = memory[account],
              (0..<Self.lifetime).contains(now.timeIntervalSince(report.updatedAt)) else { return nil }
        return report
    }

    func saved(for account: UUID) -> QuestStatistics? {
        if let report = memory[account] { return report }
        guard let file = file(for: account), let data = try? Data(contentsOf: file) else { return nil }
        return try? JSONDecoder().decode(QuestStatistics.self, from: data)
    }

    func save(_ report: QuestStatistics, for account: UUID) throws {
        memory[account] = report
        guard let directory, let file = file(for: account) else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(report).write(to: file, options: [.atomic, .completeFileProtection])
    }

    func invalidate() {
        memory.removeAll()
        revision = UUID()
    }

    func clear() throws {
        invalidate()
        guard let directory, FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    private func file(for account: UUID) -> URL? {
        directory?.appendingPathComponent(account.uuidString).appendingPathExtension("json")
    }
}

@MainActor
final class QuestStatisticsViewModel: ObservableObject {
    enum Status: Equatable {
        case loading, ready, offline, failed, signedOut
    }

    @Published private(set) var report: QuestStatistics?
    @Published private(set) var status: Status = .loading

    private let repository = QuestStatisticsRepository(client: SupabaseManager.shared.client)
    private let store = QuestStatisticsStore.shared
    private var request = UUID()
    private var displayedAccount: UUID?

    func load(connected: Bool, force: Bool = false) async {
        let currentRequest = UUID()
        request = currentRequest

        guard let account = repository.currentAccount else {
            report = nil
            status = .signedOut
            return
        }

        if displayedAccount != account {
            displayedAccount = account
            report = nil
            status = .loading
        }
        if report == nil {
            report = store.saved(for: account)
        }
        guard connected else {
            status = .offline
            return
        }

        if !force, status != .offline, status != .failed, let fresh = store.cached(for: account) {
            report = fresh
            status = .ready
            return
        }

        status = .loading

        do {
            while !Task.isCancelled {
                let revision = store.revision
                let fresh = try await repository.fetch(for: account)
                try Task.checkCancellation()
                guard request == currentRequest, repository.currentAccount == account else { return }
                guard revision == store.revision else { continue }

                report = fresh
                status = .ready
                do {
                    try store.save(fresh, for: account)
                } catch {
                    print("Could not save quest statistics:", error)
                }
                return
            }
        } catch {
            guard !Task.isCancelled, request == currentRequest else { return }
            if repository.currentAccount != account {
                report = nil
                status = .signedOut
            } else {
                status = .failed
            }
        }
    }
}
