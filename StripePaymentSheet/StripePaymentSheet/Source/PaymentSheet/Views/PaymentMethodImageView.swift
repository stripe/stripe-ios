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
        guard let imageType else {
            return
        }
        switch imageType {
        case .collectionView(let paymentMethod, let overrideUserInterfaceStyle, let iconStyle):
            let image = paymentMethod.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle, iconStyle: iconStyle, cardArtEnabled: cardArtEnabled) { [weak self] image in
                DispatchQueue.main.async {
                    self?.setImage(image)
                }
            }
            setImage(image)
        case .collectionViewApplePay(let overrideUserInterfaceStyle):
            let image = PaymentOption.applePay.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
            setImage(image)
        case .collectionViewLink(let overrideUserInterfaceStyle):
            let image = PaymentOption.link(option: .wallet).makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
            setImage(image)
        case .rowButton(let paymentMethod, let iconStyle):
            let image = paymentMethod.makeSavedPaymentMethodRowImage(iconStyle: iconStyle, cardArtEnabled: cardArtEnabled) { [weak self] image in
                DispatchQueue.main.async {
                    let roundedImage = image.roundedWithBorder(radius: 3)
                    self?.setImage(roundedImage)
                }
            }
            setImage(image)
        }
    }

    private func setImage(_ image: UIImage) {
        self.image = image
        tintColor = nil
    }
}
