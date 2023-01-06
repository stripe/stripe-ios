//
//  DownloadManager.swift
//  StripeCore
//

import CoreGraphics
import Foundation
import UIKit

/// For internal SDK use only.
@objc(STP_Internal_DownloadManager)
@_spi(STP) public class DownloadManager: NSObject, URLSessionDelegate {
    public typealias UpdateImageHandler = (UIImage) -> Void

    public static let sharedManager = DownloadManager()

    let downloadQueue: DispatchQueue
    let downloadOperationQueue: OperationQueue
    let session: URLSession!

    var imageCache: [String: UIImage]
    var pendingRequests: [String: URLSessionTask]
    var updateHandlers: [String: [UpdateImageHandler]]

    let imageCacheSemaphore: DispatchSemaphore
    let pendingRequestsSemaphore: DispatchSemaphore

    let STPCacheExpirationInterval = (60 * 60 * 24 * 7)  // 1 week
    var urlCache: URLCache?

    public init(
        urlSessionConfiguration: URLSessionConfiguration = .default
    ) {
        downloadQueue = DispatchQueue(label: "Stripe Download Cache", attributes: .concurrent)
        downloadOperationQueue = OperationQueue()
        downloadOperationQueue.underlyingQueue = downloadQueue

        let configuration = urlSessionConfiguration
        if #available(iOS 13.0, *) {
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
                self.urlCache = cache
            }
        }

        session = URLSession(configuration: configuration)

        imageCache = [:]
        pendingRequests = [:]
        updateHandlers = [:]

        imageCacheSemaphore = DispatchSemaphore(value: 1)
        pendingRequestsSemaphore = DispatchSemaphore(value: 1)

        super.init()
    }
}

// MARK: - Download management
extension DownloadManager {
    public func downloadImage(url: URL, updateHandler: UpdateImageHandler?) -> UIImage {
        if updateHandler == nil {
            return downloadImageBlocking(url: url)
        } else {
            return downloadImageAsync(url: url, updateHandler: updateHandler)
        }
    }

    func downloadImageBlocking(url: URL) -> UIImage {
        let imageName = imageNameFromURL(url: url)
        if let image = cachedImageNamed(imageName) {
            return image
        }

        var blockingDownloadedImage: UIImage?
        let updateHandler: UpdateImageHandler = { image in
            blockingDownloadedImage = image
        }
        let blockingDownloadSemaphore = DispatchSemaphore(value: 0)

        let urlRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)
        let task = self.session.downloadTask(with: url) { tempURL, response, _ in
            guard let tempURL = tempURL,
                let response = response,
                let data = self.getDataFromURL(tempURL),
                let image = self.persistToMemory(data, forImageName: imageName)
            else {
                blockingDownloadSemaphore.signal()
                return
            }
            self.urlCache?.storeCachedResponse(
                CachedURLResponse(response: response, data: data),
                for: urlRequest
            )
            updateHandler(image)
            blockingDownloadSemaphore.signal()
        }
        task.resume()
        blockingDownloadSemaphore.wait()
        return blockingDownloadedImage ?? imagePlaceHolder()
    }

    func downloadImageAsync(url: URL, updateHandler: UpdateImageHandler?) -> UIImage {
        let imageName = imageNameFromURL(url: url)
        if let image = cachedImageNamed(imageName) {
            return image
        }
        let urlRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)
        let task = self.session.downloadTask(with: url) { tempURL, response, _ in
            guard let tempURL = tempURL,
                let response = response,
                let data = self.getDataFromURL(tempURL),
                let image = self.persistToMemory(data, forImageName: imageName)
            else {
                self.pendingRequestsSemaphore.wait()
                self.pendingRequests.removeValue(forKey: imageName)
                self.pendingRequestsSemaphore.signal()
                return
            }
            self.urlCache?.storeCachedResponse(
                CachedURLResponse(response: response, data: data),
                for: urlRequest
            )

            self.pendingRequestsSemaphore.wait()
            self.pendingRequests.removeValue(forKey: imageName)
            let updates = self.updateHandlers[imageName] ?? []
            self.updateHandlers.removeValue(forKey: imageName)
            self.pendingRequestsSemaphore.signal()

            for updateHandler in updates {
                updateHandler(image)
            }
        }

        self.pendingRequestsSemaphore.wait()
        guard self.pendingRequests[imageName] == nil else {
            addUpdateHandlerWithoutLocking(updateHandler, forImageName: imageName)
            self.pendingRequestsSemaphore.signal()
            return imagePlaceHolder()
        }
        self.pendingRequests[imageName] = task
        addUpdateHandlerWithoutLocking(updateHandler, forImageName: imageName)
        self.pendingRequestsSemaphore.signal()
        task.resume()

        return imagePlaceHolder()
    }

    func imageNameFromURL(url: URL) -> String {
        return url.lastPathComponent
    }

    func addUpdateHandlerWithoutLocking(
        _ handler: UpdateImageHandler?,
        forImageName imageName: String
    ) {
        guard let handler = handler else {
            return
        }
        if let blocks = self.updateHandlers[imageName] {
            self.updateHandlers[imageName] = blocks + [handler]
        } else {
            self.updateHandlers[imageName] = [handler]
        }
    }

    func getDataFromURL(_ tempURL: URL) -> Data? {
        do {
            let imageData = try Data(contentsOf: tempURL)
            return imageData
        } catch {
        }
        return nil
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
        self.urlCache?.removeAllCachedResponses()
    }

    func persistToMemory(_ imageData: Data, forImageName imageName: String) -> UIImage? {
        guard let image = UIImage(data: imageData, scale: UIScreen.main.scale) else {
            return nil
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
