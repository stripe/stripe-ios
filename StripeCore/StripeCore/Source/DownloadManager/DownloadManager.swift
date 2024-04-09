//
//  DownloadManager.swift
//  StripeCore
//

import CoreGraphics
import Foundation
import UIKit

/// For internal SDK use only.
@objc(STP_Internal_DownloadManager)
@_spi(STP) public class DownloadManager: NSObject {
    public typealias UpdateImageHandler = (UIImage) -> Void

    enum Error: Swift.Error {
        case failedToMakeImageFromData
    }

    public static let sharedManager = DownloadManager()

    let session: URLSession
    let analyticsClient: STPAnalyticsClient
    let imageCacheSemaphore = DispatchSemaphore(value: 1)

    var imageCache: [String: UIImage] = [:]
    var diskCache: URLCache?

    public init(
        urlSessionConfiguration: URLSessionConfiguration = .default,
        analyticsClient: STPAnalyticsClient = .sharedClient
    ) {
        let configuration = urlSessionConfiguration
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first
        {
            let diskCacheURL = cachesURL.appendingPathComponent("STPCache")
            // 5MB memory cache, 30MB Disk cache
            let cache = URLCache(
                memoryCapacity: 5_000_000,
                diskCapacity: 30_000_000,
                directory: diskCacheURL
            )
            configuration.urlCache = cache
            configuration.requestCachePolicy = .useProtocolCachePolicy
            self.diskCache = cache
        }

        session = URLSession(configuration: configuration)
        self.analyticsClient = analyticsClient
        super.init()
    }
}

// MARK: - Download management
extension DownloadManager {
    public func downloadImage(url: URL, placeholder: UIImage?, updateHandler: UpdateImageHandler?) -> UIImage {
        // Early exit for cached images
        if let image = cachedImageNamed(imageNameFromURL(url: url)) {
            return image
        }

        let placeholder = placeholder ?? imagePlaceHolder()
        // If no `updateHandler` is provided use a blocking method to fetch the image
        guard let updateHandler else {
            return downloadImageBlocking(placeholder: placeholder, url: url)
        }

        Task {
           await downloadImageAsync(url: url, placeholder: placeholder, updateHandler: updateHandler)
        }
        // Immediately return a placeholder, when the download operation completes `updateHandler` will be called with the downloaded image
        return placeholder
    }

    // Common download function
    @discardableResult
    func downloadImage(url: URL, placeholder: UIImage) async -> UIImage {
        let imageName = imageNameFromURL(url: url)
        let urlRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            let image = try persistToMemory(data, forImageName: imageName) // Throws a Error.failedToMakeImageFromData
            diskCache?.storeCachedResponse(CachedURLResponse(response: response, data: data), for: urlRequest)
            return image
        } catch {
            let errorAnalytic = ErrorAnalytic(event: .stripeCoreDownloadManagerError,
                                              error: error,
                                              additionalNonPIIParams: ["url": url.absoluteString])
            analyticsClient.log(analytic: errorAnalytic)
            return placeholder
        }
    }

    func downloadImageBlocking(placeholder: UIImage, url: URL) -> UIImage {
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            _ = await downloadImage(url: url, placeholder: placeholder)
            semaphore.signal()
        }

        semaphore.wait()
        // Read from the cache as a workaround for making an async operation sync
        return cachedImageNamed(imageNameFromURL(url: url)) ?? placeholder
    }

    func downloadImageAsync(url: URL, placeholder: UIImage, updateHandler: UpdateImageHandler) async {
        let image = await downloadImage(url: url, placeholder: placeholder)
        // Only invoke the `updateHandler` if the fetched image differs from the placeholder we already vended
        if !image.isEqualToImage(image: placeholder) {
            updateHandler(image)
        }
    }

    func imageNameFromURL(url: URL) -> String {
        return url.lastPathComponent
    }
}

// MARK: Image Cache
extension DownloadManager {
    func resetMemoryCache() {
        imageCacheSemaphore.wait()
        self.imageCache = [:]
        imageCacheSemaphore.signal()
    }

    func resetDiskCache() {
        self.diskCache?.removeAllCachedResponses()
    }

    func persistToMemory(_ imageData: Data, forImageName imageName: String) throws -> UIImage {
        #if canImport(CompositorServices)
        let scale = 1.0
        #else
        let scale = UIScreen.main.scale
        #endif
        guard let image = UIImage(data: imageData, scale: scale) else {
            throw Error.failedToMakeImageFromData
        }
        imageCacheSemaphore.wait()
        self.imageCache[imageName] = image
        imageCacheSemaphore.signal()
        return image
    }

    func cachedImageNamed(_ imageName: String) -> UIImage? {
        var image: UIImage?
        imageCacheSemaphore.wait()
        image = imageCache[imageName]
        imageCacheSemaphore.signal()
        return image
    }
}

// MARK: Image Placeholder
extension DownloadManager {
    public func imagePlaceHolder() -> UIImage {
        return imageWithSize(size: CGSize(width: 1.0, height: 1.0))
    }

    func imageWithSize(size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.clear.set()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

// MARK: UIImage helper
extension UIImage {

    func isEqualToImage(image: UIImage) -> Bool {
        return self.pngData() == image.pngData()
    }

}
