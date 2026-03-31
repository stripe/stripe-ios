//
//  UIImageView+Extensions.swift
//  StripePaymentSheet
//

import UIKit

extension UIImageView {
    // Helper extension for downloading and setting image. Optionally process it before setting.
    // On failure or no URL, set fallback image.
    func setImage(
        with url: URL?,
        fallbackImage: UIImage,
        processOnDownloadedImage: ((UIImage) -> UIImage)? = nil
    ) {
        guard let url else {
            self.image = fallbackImage
            return
        }

        // We use `tag` to ensure that if we call `setImage(with:)` multiple times,
        // we ONLY set the image from the `urlString` for the last `urlString` passed.
        //
        // This avoids async bugs where an older image could override a newer image.
        tag = url.hashValue
        Task { [weak self] in
            do {
                let image = try await DownloadManager.sharedManager.downloadImage(url: url)
                await MainActor.run {
                    let processedImage = processOnDownloadedImage?(image) ?? image
                    if self?.tag == url.hashValue {
                        self?.image = processedImage
                    }
                }
            } catch {
                await MainActor.run {
                    if self?.tag == url.hashValue {
                        self?.image = fallbackImage
                    }
                }
            }
        }
    }
}
