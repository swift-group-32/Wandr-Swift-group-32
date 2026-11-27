
import Foundation
import Combine
import UIKit

@MainActor
final class PhotoJournalViewModel: ObservableObject {

    @Published private(set) var report: PhotoJournalReport?
    @Published private(set) var isLoading = false
    @Published private(set) var isOffline = false
    @Published var message: String?


    @Published var selectedCategory: String? {
        didSet { updateVisiblePhotos() }
    }
    
    @Published private(set) var visiblePhotos: [JournalPhoto] = []

    
    private(set) var remoteURLs: [String: URL] = [:]

    private let service: PhotoJournalServing
    private let storage: PhotoJournalStorage
    private let images: ImagePipeline
    private let network: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    private var userId: String?
    private var refreshTask: Task<Void, Never>?

    nonisolated static let thumbnailPixels = 360
    nonisolated static let fullPixels = 1600
    
    private let prefetchLimit = 24
    private let maxParallelDownloads = 4

    init(
        service: PhotoJournalServing? = nil,
        storage: PhotoJournalStorage = .shared,
        images: ImagePipeline = .shared,
        network: NetworkMonitor? = nil
    ) {
        
        let network = network ?? NetworkMonitor.shared
        self.service = service ?? PhotoJournalRepository()
        self.storage = storage
        self.images = images
        self.network = network

        
        network.$isConnected
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                guard let self else { return }
                self.isOffline = !connected
                if connected {
                    self.refresh()
                } else {
                    self.refreshTask?.cancel()
                    self.isLoading = false
                    self.message = self.offlineMessage()
                }
            }
            .store(in: &cancellables)
    }

    

    func load() async {
        isOffline = !network.isConnected

        guard let userId = try? await service.currentUserId() else {
            message = "Log in again to see your journal."
            return
        }
        self.userId = userId

        
        if let cached = storage.cached(userId: userId) {
            apply(cached)
            if storage.isFresh(userId: userId) { return }
        }

        
        if report == nil {
            let storage = self.storage
            let saved = await Task.detached(priority: .userInitiated) {
                storage.loadFromDisk(userId: userId)
            }.value
            if let saved { apply(saved) }
        }

        
        if network.isConnected {
            await fetchFromNetwork()
        } else {
            message = offlineMessage()
        }
    }

    
    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { await fetchFromNetwork() }
    }

    func refreshAndWait() async {
        refresh()
        await refreshTask?.value
    }

    private func fetchFromNetwork() async {
        guard network.isConnected else {
            message = offlineMessage()
            return
        }
        
        var currentUser = self.userId
        if currentUser == nil {
            currentUser = try? await service.currentUserId()
        }
        guard let userId = currentUser else { return }
        self.userId = userId

        isLoading = true
        message = nil

        let slowTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, let self, self.isLoading else { return }
            self.message = self.report == nil
                ? "Slow connection. Still loading your journal..."
                : "Slow connection. Showing your saved journal while it updates..."
        }
        defer { slowTimer.cancel() }

        do {
            let rows = try await service.fetchCompletedQuests()
            try Task.checkCancellation()
            
        
            let storage = self.storage
            let newReport = await Task.detached(priority: .userInitiated) {
                let report = PhotoJournalCalculator.makeReport(from: rows)
                storage.save(report, userId: userId)
                return report
            }.value
            try Task.checkCancellation()

            apply(newReport)
            isLoading = false
            message = nil

            await prepareThumbnails(for: newReport.photos)
        } catch is CancellationError {
            isLoading = false
        } catch {
            isLoading = false
            
            if Task.isCancelled { return }
            print("PhotoJournal error:", error)
            message = network.isConnected
                ? (report == nil
                   ? "Could not load your journal. Pull down to try again."
                   : "Could not update. Showing your saved journal.")
                : offlineMessage()
        }
    }

    
    private func prepareThumbnails(for photos: [JournalPhoto]) async {
        var missing: [String] = []
        for photo in photos {
            let isSaved = await images.hasLocalCopy(forKey: photo.thumbnailKey)
            if !isSaved { missing.append(photo.path) }
        }
        guard !missing.isEmpty else { return }

        guard let urls = try? await service.signedURLs(for: missing) else { return }
        remoteURLs.merge(urls) { _, new in new }
        objectWillChange.send()

        
        let queue: [(String, URL)] = missing.prefix(prefetchLimit).compactMap { path in
            urls[path].map { ("journal-thumb|\(path)", $0) }
        }
        let images = self.images
        let pixels = Self.thumbnailPixels
        let limit = maxParallelDownloads

        
        await withTaskGroup(of: Void.self) { group in
            var next = 0
            while next < queue.count && next < limit {
                let (path, url) = queue[next]
                group.addTask(priority: .utility) {
                    _ = await images.image(forKey: path, url: url, maxPixelSize: pixels)
                }
                next += 1
            }
            while await group.next() != nil {
                if Task.isCancelled { group.cancelAll(); break }
                guard next < queue.count else { continue }
                let (path, url) = queue[next]
                group.addTask(priority: .utility) {
                    _ = await images.image(forKey: path, url: url, maxPixelSize: pixels)
                }
                next += 1
            }
        }
    }

    func url(for photo: JournalPhoto) -> URL? {
        remoteURLs[photo.path]
    }

    
    func detailURL(for photo: JournalPhoto) async -> URL? {
        if let url = remoteURLs[photo.path] { return url }
        guard network.isConnected,
              let urls = try? await service.signedURLs(for: [photo.path]),
              let url = urls[photo.path] else { return nil }
        remoteURLs[photo.path] = url
        return url
    }



    private func apply(_ report: PhotoJournalReport) {
        self.report = report
        if let selected = selectedCategory,
           !report.categories.contains(where: { $0.category == selected && $0.documentedQuests > 0 }) {
            selectedCategory = nil   // didSet updates the list
        } else {
            updateVisiblePhotos()
        }
    }

    private func updateVisiblePhotos() {
        let photos = report?.photos ?? []
        guard let selectedCategory else {
            visiblePhotos = photos
            return
        }
        visiblePhotos = photos.filter { $0.category == selectedCategory }
    }

    var documentedCategories: [DocumentedCategory] {
        report?.categories.filter { $0.documentedQuests > 0 } ?? []
    }

    var summaryText: String {
        guard let report else { return "" }
        if report.completedQuests == 0 {
            return "Complete your first quest to start your journal."
        }
        if report.documentedQuests == 0 {
            return "None of your \(report.completedQuests) completed quests has a photo yet. Add one on your next quest!"
        }
        let word = report.completedQuests == 1 ? "quest" : "quests"
        return "\(report.documentedQuests) of your \(report.completedQuests) completed \(word) have photo proof."
    }

    func offlineMessage() -> String {
        if let report {
            let date = report.generatedAt.formatted(date: .abbreviated, time: .shortened)
            return "You're offline. Showing your journal saved on \(date). It will update when the internet comes back."
        }
        return "You're offline and your journal is not saved on this phone yet. Connect to the internet to load it."
    }
}
