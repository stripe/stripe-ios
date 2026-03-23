//
//  PaymentMethodImageView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import UIKit

/// A convenience UIImageView that displays the payment method image, handles the download if needed
class PaymentMethodImageView: UIImageView {
    enum ImageType {
        case collectionView(STPPaymentMethod, UIUserInterfaceStyle, PaymentSheet.Appearance.IconStyle)
        case collectionViewApplePay(UIUserInterfaceStyle)
        case collectionViewLink(UIUserInterfaceStyle)
        case rowButton(STPPaymentMethod, PaymentSheet.Appearance.IconStyle)
    }
    var imageType: ImageType?
    var cardArtEnabled: Bool = false
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

    func set(_ imageType: ImageType, cardArtEnabled: Bool) {
        self.cardArtEnabled = cardArtEnabled
        self.imageType = imageType
        updateImage()
    }

    func updateImage() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil

        guard let imageType else {
            return
        }
        switch imageType {
        case .collectionView(let paymentMethod, let overrideUserInterfaceStyle, let iconStyle):
            let image = paymentMethod.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle, iconStyle: iconStyle)
            if cardArtEnabled, let cardArtURL = paymentMethod.cardArtURL(height: 40) {
                downloadCardArt(url: cardArtURL, fallback: image)
            } else {
                setImage(image)
            }
        case .collectionViewApplePay(let overrideUserInterfaceStyle):
            let image = PaymentOption.applePay.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
            setImage(image)
        case .collectionViewLink(let overrideUserInterfaceStyle):
            let image = PaymentOption.link(option: .wallet).makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
            setImage(image)
        case .rowButton(let paymentMethod, let iconStyle):
            let image = paymentMethod.makeSavedPaymentMethodRowImage(iconStyle: iconStyle)
            if cardArtEnabled, let cardArtURL = paymentMethod.cardArtURL(height: 20) {
                downloadCardArt(url: cardArtURL, fallback: image, postProcess: { $0.roundedWithBorder(radius: 3) })
            } else {
                setImage(image)
            }
        }
    }

    private func downloadCardArt(url: URL, fallback: UIImage, postProcess: ((UIImage) -> UIImage)? = nil) {
        currentDownloadTask = Task { [weak self] in
            do {
                let image = try await DownloadManager.sharedManager.downloadImage(url: url)
                guard !Task.isCancelled else { return }
                let finalImage = postProcess?(image) ?? image
                self?.setImage(finalImage)
            } catch {
                guard !Task.isCancelled else { return }
                let finalFallback = postProcess?(fallback) ?? fallback
                self?.setImage(finalFallback)
            }
        }
    }

    private func setImage(_ image: UIImage) {
        self.image = image
        tintColor = nil
    }
}
