//
//  PhotoJournalStorage.swift
//  Wandr-Swift-group-32
//
//  Local storage + cache for the Photo Journal.
//  - Disk: the last report is saved as a JSON file per user in
//    Application Support (not deleted by iOS, unlike Caches).
//  - Memory: NSCache with a 5 minute freshness window, so going back and
//    forth from Profile does not repeat the request.
//  The photos themselves are stored by ImagePipeline (Library/Caches).
//

import Foundation

nonisolated final class PhotoJournalStorage: @unchecked Sendable {

    static let shared = PhotoJournalStorage()

    nonisolated private final class Entry {
        let report: PhotoJournalReport
        let savedAt: Date
        init(_ report: PhotoJournalReport, savedAt: Date) {
            self.report = report
            self.savedAt = savedAt
        }
    }

    // NSCache is thread safe.
    private let memory = NSCache<NSString, Entry>()
    private let directory: URL
    let maxAge: TimeInterval = 5 * 60

    init(directoryName: String = "PhotoJournal") {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = support.appendingPathComponent(directoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: - Memory cache

    func cached(userId: String) -> PhotoJournalReport? {
        memory.object(forKey: userId as NSString)?.report
    }

    func isFresh(userId: String, now: Date = Date()) -> Bool {
        guard let entry = memory.object(forKey: userId as NSString) else { return false }
        let age = now.timeIntervalSince(entry.savedAt)
        return age >= 0 && age < maxAge
    }

    // MARK: - Disk

    /// Reads the saved report. Called from a background task.
    func loadFromDisk(userId: String) -> PhotoJournalReport? {
        guard let data = try? Data(contentsOf: fileURL(userId: userId)),
              let report = try? JSONDecoder().decode(PhotoJournalReport.self, from: data) else {
            return nil
        }
        // Put it in memory but keep it "not fresh": it may be old.
        memory.setObject(Entry(report, savedAt: .distantPast), forKey: userId as NSString)
        return report
    }

    func save(_ report: PhotoJournalReport, userId: String, now: Date = Date()) {
        memory.setObject(Entry(report, savedAt: now), forKey: userId as NSString)
        do {
            let data = try JSONEncoder().encode(report)
            // Complete file protection: unreadable while the phone is locked.
            try data.write(to: fileURL(userId: userId), options: [.atomic, .completeFileProtection])
        } catch {
            print("PhotoJournal save error:", error)
        }
    }

    func clear(userId: String) {
        memory.removeObject(forKey: userId as NSString)
        try? FileManager.default.removeItem(at: fileURL(userId: userId))
    }

    /// Called on log out: the journal of one account must not be shown to the next one.
    func clearAll() {
        memory.removeAllObjects()
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileURL(userId: String) -> URL {
        let safe = userId.filter { $0.isLetter || $0.isNumber || $0 == "-" }
        return directory.appendingPathComponent("journal_\(safe).json")
    }
}
