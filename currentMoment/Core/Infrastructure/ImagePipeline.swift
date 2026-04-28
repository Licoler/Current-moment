import Foundation
import UIKit

@MainActor
final class ImagePipeline {
    static let shared = ImagePipeline()
    
    private let cache = NSCache<NSURL, UIImage>()
    
    func image(for path: String?) async -> UIImage? {
        guard let path else {
            return nil
        }
        
        let url: URL
        if let remoteURL = URL(string: path), remoteURL.scheme != nil {
            url = remoteURL
        } else {
            url = URL(fileURLWithPath: path)
        }
        
        let cacheKey = url as NSURL
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }
        
        let image: UIImage?
        if url.isFileURL {
            image = UIImage(contentsOfFile: url.path)
        } else {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                image = UIImage(data: data)
            } catch {
                image = nil
            }
        }
        
        if let image {
            cache.setObject(image, forKey: cacheKey)
        }
        
        return image
    }
}
