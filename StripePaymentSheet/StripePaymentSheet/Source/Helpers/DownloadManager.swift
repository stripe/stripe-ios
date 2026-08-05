//
//  DownloadManager.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/// Downloads images and caches both their responses and decoded representations.
@_spi(STP) public final class DownloadManager {
    // Keep this internal: ErrorAnalytic records its reflected type name.
    enum Error: Swift.Error {
        case failedToMakeImageFromData
    }

    public static let shared = DownloadManager()

    private static let decodedImageCacheCostLimit = 5_000_000
    private static let responseCacheMemoryCapacity = 5_000_000
    private static let responseCacheDiskCapacity = 30_000_000

    private let session: URLSession
    private let analyticsClient: STPAnalyticsClient
    private let imageCache = NSCache<NSURL, UIImage>()

    private convenience init() {
        self.init(urlSessionConfiguration: Self.makeDefaultConfiguration())
    }

    init(
        urlSessionConfiguration: URLSessionConfiguration,
        analyticsClient: STPAnalyticsClient = .sharedClient
    ) {
        session = URLSession(configuration: urlSessionConfiguration)
        self.analyticsClient = analyticsClient
        imageCache.totalCostLimit = Self.decodedImageCacheCostLimit
    }

    /// Returns an image from the in-memory cache without performing any I/O.
    public func cachedImage(for url: URL) -> UIImage? {
        imageCache.object(forKey: url as NSURL)
    }

    /// Synchronously promotes an image from the URL response cache into the decoded image cache.
    func promoteCachedImage(for url: URL) -> UIImage? {
        if let image = cachedImage(for: url) {
            return image
        }

        let request = URLRequest(url: url)
        guard let data = session.configuration.urlCache?.cachedResponse(for: request)?.data,
              let image = try? Self.decodeImage(from: data) else {
            return nil
        }
        cache(image, for: url as NSURL)
        return image
    }

    /// Returns the image at `url`, using cached data whenever possible.
    public func image(for url: URL) async throws -> UIImage {
        if let image = cachedImage(for: url) {
            return image
        }

        var errorParams: [String: Any] = ["url": url.absoluteString]
        do {
            let (data, response) = try await session.data(from: url)
            if let response = response as? HTTPURLResponse {
                errorParams["http_status"] = response.statusCode
                errorParams["content_type"] = response.value(forHTTPHeaderField: "Content-Type")
                errorParams["content_length"] = response.value(forHTTPHeaderField: "Content-Length")
            }

            let image = try Self.decodeImage(from: data)
            cache(image, for: url as NSURL)
            return image
        } catch {
            if (error as? URLError)?.code != .cancelled {
                analyticsClient.log(
                    analytic: ErrorAnalytic(
                        event: .stripePaymentSheetDownloadManagerError,
                        error: error,
                        additionalNonPIIParams: errorParams
                    )
                )
            }
            throw error
        }
    }

    func clearCache() {
        session.configuration.urlCache?.removeAllCachedResponses()
        imageCache.removeAllObjects()
    }

    private func cache(_ image: UIImage, for key: NSURL) {
        imageCache.setObject(image, forKey: key, cost: image.decodedByteCount)
    }

    private static func decodeImage(from data: Data) throws -> UIImage {
        #if os(visionOS)
        let scale = 1.0
        #else
        let scale = UIScreen.main.scale
        #endif
        guard let image = UIImage(data: data, scale: scale) else {
            throw Error.failedToMakeImageFromData
        }
        return image
    }

    private static func makeDefaultConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("STPCache")
        configuration.urlCache = URLCache(
            memoryCapacity: responseCacheMemoryCapacity,
            diskCapacity: responseCacheDiskCapacity,
            directory: directory
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return configuration
    }
}

private extension UIImage {
    var decodedByteCount: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
