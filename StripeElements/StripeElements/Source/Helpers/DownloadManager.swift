//
//  DownloadManager.swift
//  StripeCore
//

import CoreGraphics
import Foundation
@_spi(STP) import StripeCore
import UIKit

/// For internal SDK use only.
@objc(STP_Internal_DownloadManager)
// TODO: https://jira.corp.stripe.com/browse/MOBILESDK-2604 Refactor this!
@_spi(STP) public class DownloadManager: NSObject {
    public typealias UpdateImageHandler = (UIImage) -> Void

    enum Error: Swift.Error {
        case failedToMakeImageFromData
    }

    public static let sharedManager = DownloadManager()

    private let session: URLSession
    private let analyticsClient: STPAnalyticsClient
    private let imageCacheLock = NSLock()
    private var imageCache: [URL: UIImage] = [:]

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
        }

        session = URLSession(configuration: configuration)
        self.analyticsClient = analyticsClient
        super.init()
    }
}

// MARK: - Download management
extension DownloadManager {

    /// Downloads an image from a provided URL, using either a synchronous method or an asynchronous method.
    /// If no `updateHandler` is provided, this function will block the current thread until the image is downloaded. If an `updateHandler` is provided, the function does not wait for the download to finish and returns the image if it was cached or a placeholder image instead. When the image finishes downloading, the `updateHandler` will be called with the downloaded image.
    /// - Parameters:
    ///   - url: The URL from which to download the image.
    ///   - placeholder: An optional parameter indicating a placeholder image to display while the download is in progress. If not provided, a default placeholder image will be used instead.
    ///   - updateHandler: An optional closure that's called when the image finishes downloading. The downloaded image is passed as a parameter to this closure.
    ///
    /// - Returns: A `UIImage` instance. If `updateHandler` is `nil`, this would be the downloaded image, otherwise, this would be the placeholder image.
    public func downloadImage(url: URL, placeholder: UIImage?, updateHandler: UpdateImageHandler?) -> UIImage {
        let placeholder = placeholder ?? imagePlaceHolder()
        imageCacheLock.lock()
        let cachedImage = imageCache[url]
        imageCacheLock.unlock()

        if let updateHandler {
            Task {
                await downloadImageAsync(url: url, placeholder: placeholder, updateHandler: updateHandler)
            }
        }
        // Immediately return the cached image or a placeholder. When the download operation completes `updateHandler` will be called with the downloaded image.
        return cachedImage ?? placeholder
    }

    // Common download function
    private func downloadImage(url: URL, placeholder: UIImage) async -> UIImage {
        do {
            let (data, _) = try await session.data(from: url)
            let image = try UIImage.from(imageData: data) // Throws a Error.failedToMakeImageFromData
            Task {
                // Cache the image in memory
                self.imageCacheLock.withLock {
                    self.imageCache[url] = image
                }

            }
            return image
        } catch {
            let errorAnalytic = ErrorAnalytic(event: .stripePaymentSheetDownloadManagerError,
                                              error: error,
                                              additionalNonPIIParams: ["url": url.absoluteString])
            analyticsClient.log(analytic: errorAnalytic)
            return placeholder
        }
    }

    private func downloadImageAsync(url: URL, placeholder: UIImage, updateHandler: UpdateImageHandler) async {
        let image = await downloadImage(url: url, placeholder: placeholder)
        // Only invoke the `updateHandler` if the fetched image differs from the placeholder we already vended
        if !image.isEqualToImage(image: placeholder) {
            updateHandler(image)
        }
    }

    func resetCache() {
        session.configuration.urlCache?.removeAllCachedResponses()
        imageCacheLock.lock()
        imageCache = [:]
        imageCacheLock.unlock()
    }
}

// MARK: Image Placeholder
extension DownloadManager {
    public func imagePlaceHolder() -> UIImage {
        return imageWithSize(size: CGSize(width: 1.0, height: 1.0))
    }

    private func imageWithSize(size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.clear.set()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

// MARK: UIImage helpers
private extension UIImage {
    func isEqualToImage(image: UIImage) -> Bool {
        return self.pngData() == image.pngData()
    }

    static func from(imageData: Data) throws -> UIImage {
        #if canImport(CompositorServices)
        let scale = 1.0
        #else
        let scale = UIScreen.main.scale
        #endif
        guard let image = UIImage(data: imageData, scale: scale) else {
            throw DownloadManager.Error.failedToMakeImageFromData
        }

        return image
    }
}
