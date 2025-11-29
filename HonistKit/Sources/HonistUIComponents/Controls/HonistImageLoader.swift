import UIKit
import Foundation
import HonistFoundation

public final class HonistImageLoader {
    public static let shared = HonistImageLoader()

    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    public func load(_ urlString: String?, into imageView: UIImageView) {
        imageView.image = UIImage(systemName: "person.circle")

        guard let urlString else { return }
        // Compose proper URL using AppEnvironment.baseURLString if needed
        let url: URL?
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            url = URL(string: urlString)
        } else {
            url = URL(string: urlString, relativeTo: URL(string: AppEnvironment.baseURLString))
        }
        guard let url else { return }

        if let cached = cache.object(forKey: urlString as NSString) {
            imageView.image = cached
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    cache.setObject(img, forKey: urlString as NSString)
                    DispatchQueue.main.async { imageView.image = img }
                }
            } catch {
                // ignore
            }
        }
    }
}
