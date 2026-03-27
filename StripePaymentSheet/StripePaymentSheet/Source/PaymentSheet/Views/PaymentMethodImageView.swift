//
//  PaymentMethodImageView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import UIKit

/// A convenience UIImageView that displays the payment method image, handles the download if needed
class PaymentMethodImageView: UIImageView {
    struct Configuration {
        let cardArtURL: URL?
        let imageFromBundle: UIImage
        let postProcess: ((UIImage) -> UIImage)?
    }

    private var configuration: Configuration?
    private var currentDownloadTask: Task<Void, Never>?

    init() {
        super.init(image: nil)
        self.contentMode = .scaleAspectFit
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateImage()
    }
#endif

    func set(_ configuration: Configuration) {
        self.configuration = configuration
        updateImage()
    }

    private func updateImage() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil

        guard let configuration else {
            return
        }

        if let url = configuration.cardArtURL {
            downloadCardArt(url: url, fallback: configuration.imageFromBundle, postProcess: configuration.postProcess)
        } else {
            setImage(configuration.imageFromBundle)
        }
    }

    private func downloadCardArt(url: URL, fallback: UIImage, postProcess: ((UIImage) -> UIImage)?) {
        currentDownloadTask = Task { [weak self] in
            do {
                let image = try await DownloadManager.sharedManager.downloadImage(url: url)
                guard !Task.isCancelled else { return }
                let postProcessedImage = postProcess?(image) ?? image
                await MainActor.run {
                    self?.setImage(postProcessedImage)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.setImage(fallback)
                }
            }
        }
    }

    private func setImage(_ image: UIImage) {
        self.image = image
        tintColor = nil
    }
}
