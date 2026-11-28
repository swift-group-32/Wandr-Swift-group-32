import Combine
import Foundation

@MainActor
final class LowUseCategoriesStore {
    static let shared = LowUseCategoriesStore(
        directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("LowUseCategories", isDirectory: true)
    )

    private let directory: URL?
    private(set) var revision = UUID()

    init(directory: URL?) {
        self.directory = directory
    }

    func load(for account: UUID) -> LowUseCategoriesReport? {
        guard let file = file(for: account), let data = try? Data(contentsOf: file) else { return nil }
        return try? JSONDecoder().decode(LowUseCategoriesReport.self, from: data)
    }

    func save(_ report: LowUseCategoriesReport, for account: UUID) throws {
        guard let directory, let file = file(for: account) else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(report).write(to: file, options: [.atomic, .completeFileProtection])
    }

    func remove(for account: UUID) throws {
        guard let file = file(for: account), FileManager.default.fileExists(atPath: file.path) else { return }
        try FileManager.default.removeItem(at: file)
    }

    func clear() throws {
        revision = UUID()
        guard let directory, FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    private func file(for account: UUID) -> URL? {
        directory?.appendingPathComponent(account.uuidString).appendingPathExtension("json")
    }
}

@MainActor
final class LowUseCategoriesViewModel: ObservableObject {
    enum Status: Equatable {
        case loading, ready, offline, failed, accessDenied
    }

    @Published private(set) var report: LowUseCategoriesReport?
    @Published private(set) var status: Status = .loading

    private let service: any LowUseCategoriesServing
    private let store: LowUseCategoriesStore
    private var displayedAccount: UUID?
    private var request = UUID()

    init(service: (any LowUseCategoriesServing)? = nil, store: LowUseCategoriesStore? = nil) {
        self.service = service ?? LowUseCategoriesService(client: SupabaseManager.shared.client)
        self.store = store ?? .shared
    }

    func load(connected: Bool, force: Bool = false, now: Date = .now) async {
        let currentRequest = UUID()
        request = currentRequest
        let revision = store.revision

        guard let account = service.currentAccount else {
            report = nil
            displayedAccount = nil
            status = .accessDenied
            return
        }

        if displayedAccount != account {
            displayedAccount = account
            report = store.load(for: account)
            status = .loading
        }

        guard connected else {
            status = .offline
            return
        }

        if !force, status != .offline, status != .failed,
           let report, (0..<300).contains(now.timeIntervalSince(report.updatedAt)) {
            status = .ready
            return
        }

        status = .loading
        do {
            let categories = try await service.fetch(for: account)
            guard canApply(currentRequest, revision: revision) else { return }
            guard service.currentAccount == account else {
                report = nil
                status = .accessDenied
                return
            }
            let fresh = LowUseCategoriesReport(categories: categories, updatedAt: now)
            report = fresh
            status = .ready
            do {
                try store.save(fresh, for: account)
            } catch {
                print("Could not save low-use categories:", error)
            }
        } catch {
            guard canApply(currentRequest, revision: revision) else { return }
            if error is LowUseCategoriesError || service.currentAccount != account {
                report = nil
                status = .accessDenied
                do {
                    try store.remove(for: account)
                } catch {
                    print("Could not remove low-use categories:", error)
                }
            } else {
                status = .failed
            }
        }
    }

    private func canApply(_ currentRequest: UUID, revision: UUID) -> Bool {
        !Task.isCancelled && request == currentRequest && store.revision == revision
    }
}
