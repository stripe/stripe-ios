//
//  UIImageView+Extensions.swift
//  StripePaymentSheet
//

import UIKit

extension UIImageView {
    /// Downloads an image from `url` and sets it on this image view, optionally processing it first.
    /// Throws if `url` is nil or the download fails.
    func setImage(
        url: URL?,
        processOnDownloadedImage: ((UIImage) -> UIImage)? = nil
    ) async throws {
        guard let url else {
            throw URLError(.badURL)
        }

        // We use `tag` to ensure that if we call `setImage(with:)` multiple times,
        // we ONLY set the image from the `urlString` for the last `urlString` passed.
        //
        // This avoids async bugs where an older image could override a newer image.
        tag = url.hashValue
        do {
            let image = try await DownloadManager.sharedManager.downloadImage(url: url)
            let processedImage = processOnDownloadedImage?(image) ?? image
            guard tag == url.hashValue else { return }
            self.image = processedImage
        } catch {
            // Check to ensure we're still setting the same url
            guard tag == url.hashValue else { return }

            // If url.hashValue hasn't changed, throw the error to handle setting a fallback if needed
            throw error
        }
    }
}
