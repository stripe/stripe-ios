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
        processOnDownloadedImage: ((UIImage) -> UIImage)? = nil,
        fallbackImage: UIImage
    ) {
        guard let url else {
            self.image = fallbackImage
            return
        }
        Task { [weak self] in
            do {
                let image = try await DownloadManager.sharedManager.downloadImage(url: url)
                guard !Task.isCancelled else { return }
                let processedImage = processOnDownloadedImage?(image) ?? image
                await MainActor.run {
                    self?.image = processedImage
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.image = fallbackImage
                }
            }
        }
    }
}
