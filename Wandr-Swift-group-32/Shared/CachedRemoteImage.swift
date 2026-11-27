
import SwiftUI
import UIKit

struct CachedRemoteImage<Placeholder: View, Failure: View>: View {

    
    let key: String
    let url: URL?
    let maxPixelSize: Int
    
    let fallbackKey: String?
    let placeholder: () -> Placeholder
    let failure: () -> Failure

    @State private var image: UIImage? = nil
    @State private var failed = false

    init(key: String, url: URL?, maxPixelSize: Int, fallbackKey: String? = nil,
         @ViewBuilder placeholder: @escaping () -> Placeholder,
         @ViewBuilder failure: @escaping () -> Failure) {
        self.key = key
        self.url = url
        self.maxPixelSize = maxPixelSize
        self.fallbackKey = fallbackKey
        self.placeholder = placeholder
        self.failure = failure
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if failed {
                failure()
            } else {
                placeholder()
            }
        }
        .task(id: "\(key)|\(url?.absoluteString ?? "")") {
            await load()
        }
    }

    private func load() async {
        let pipeline = ImagePipeline.shared
        
        if let memory = pipeline.memoryImage(forKey: key) {
            image = memory
            failed = false
            return
        }
        if image == nil, let fallbackKey, let low = pipeline.memoryImage(forKey: fallbackKey) {
            image = low
        }
        let loaded = await pipeline.image(forKey: key, url: url, maxPixelSize: maxPixelSize)
        guard !Task.isCancelled else { return }
        if let loaded {
            image = loaded
            failed = false
        } else if image == nil {
            
            failed = url != nil
        }
    }
}

extension CachedRemoteImage where Failure == Placeholder {
    init(key: String, url: URL?, maxPixelSize: Int, fallbackKey: String? = nil,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.init(key: key, url: url, maxPixelSize: maxPixelSize, fallbackKey: fallbackKey,
                  placeholder: placeholder, failure: placeholder)
    }
}
