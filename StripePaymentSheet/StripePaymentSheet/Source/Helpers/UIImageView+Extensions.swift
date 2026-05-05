//
//  UIImageView+Extensions.swift
//  StripePaymentSheet
//

@_spi(STP) import StripePaymentsUI
import UIKit

extension UIImageView {
    // Helper extension for downloading and setting image. Optionally process it before setting.
    // On failure or no URL, set fallback image.
    // - shimmeringImage: If provided, displayed with a shimmer animation overlay while the download is in progress.
    func setImage(
        with url: URL?,
        processOnDownloadedImage: ((UIImage) -> UIImage)? = nil,
        fallbackImage: UIImage,
        shimmeringImage: UIImage?
    ) {
        guard let url else {
            self.image = fallbackImage
            return
        }

        if let shimmeringImage {
            self.image = shimmeringImage
            addShimmer()
        }

        // We use `tag` to ensure that if we call `setImage(with:)` multiple times,
        // we ONLY set the image from the `urlString` for the last `urlString` passed.
        //
        // This avoids async bugs where an older image could override a newer image.
        tag = url.hashValue
        Task { [weak self] in
            do {
                let image = try await DownloadManager.sharedManager.downloadImage(url: url)
                let processedImage = processOnDownloadedImage?(image) ?? image
                await MainActor.run {
                    if self?.tag == url.hashValue {
                        self?.image = processedImage
                        self?.removeShimmer()
                    }
                }
            } catch {
                await MainActor.run {
                    if self?.tag == url.hashValue {
                        self?.image = fallbackImage
                        self?.removeShimmer()
                    }
                }
            }
        }
    }

    func addShimmer() {
        removeShimmer()
        let shimmer = ShimmerView()
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        addSubview(shimmer)
        NSLayoutConstraint.activate([
            shimmer.topAnchor.constraint(equalTo: topAnchor),
            shimmer.bottomAnchor.constraint(equalTo: bottomAnchor),
            shimmer.leadingAnchor.constraint(equalTo: leadingAnchor),
            shimmer.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    func removeShimmer() {
        subviews.compactMap { $0 as? ShimmerView }.forEach { $0.stopShimmering() }
    }
}
