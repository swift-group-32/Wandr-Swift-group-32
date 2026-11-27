

import Foundation
import UIKit
import ImageIO
import CryptoKit

actor ImagePipeline {

    static let shared = ImagePipeline()

    
    nonisolated(unsafe) private let memory = NSCache<NSString, UIImage>()
    private let directory: URL
    private let session: URLSession
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    init(folderName: String = "ImagePipeline") {
        memory.totalCostLimit = 40 * 1024 * 1024
        memory.countLimit = 300

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = 20
        session = URLSession(configuration: configuration)
    }


    nonisolated func memoryImage(forKey key: String) -> UIImage? {
        memory.object(forKey: key as NSString)
    }

    func cachedImage(forKey key: String, maxPixelSize: Int) -> UIImage? {
        if let image = memory.object(forKey: key as NSString) { return image }
        guard let data = try? Data(contentsOf: fileURL(for: key)),
              let image = ImageDownsampler.downsample(data, maxPixelSize: maxPixelSize) else {
            return nil
        }
        store(image, forKey: key)
        return image
    }

    func image(forKey key: String, url: URL?, maxPixelSize: Int) async -> UIImage? {
        if let cached = cachedImage(forKey: key, maxPixelSize: maxPixelSize) { return cached }
        guard let url else { return nil }

        if let running = inFlight[key] { return await running.value }

        let destination = fileURL(for: key)
        let session = self.session
        let task = Task<UIImage?, Never>.detached(priority: .utility) {
            guard let result = try? await session.data(from: url),
                  ((result.1 as? HTTPURLResponse)?.statusCode ?? 200) < 400 else {
                return nil
            }
            let data = result.0

            guard let image = ImageDownsampler.downsample(data, maxPixelSize: maxPixelSize) else { return nil }
            if let jpeg = image.jpegData(compressionQuality: 0.8) {
                try? jpeg.write(to: destination, options: .atomic)
            }
            return image
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image { store(image, forKey: key) }
        return image
    }

    func hasLocalCopy(forKey key: String) -> Bool {
        memory.object(forKey: key as NSString) != nil
            || FileManager.default.fileExists(atPath: fileURL(for: key).path)
    }

    func removeAll() {
        memory.removeAllObjects()
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }


    private func store(_ image: UIImage, forKey key: String) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        memory.setObject(image, forKey: key as NSString, cost: cost)
    }

    private func fileURL(for key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name).appendingPathExtension("jpg")
    }
}


nonisolated enum ImageDownsampler {

    static func downsample(_ data: Data, maxPixelSize: Int) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    
    static func compressForUpload(_ data: Data, maxPixelSize: Int = 1600, quality: CGFloat = 0.7) async -> Data {
        await Task.detached(priority: .userInitiated) {
            guard let image = ImageDownsampler.downsample(data, maxPixelSize: maxPixelSize),
                  let jpeg = image.jpegData(compressionQuality: quality) else {
                return data
            }
            return jpeg
        }.value
    }
}
