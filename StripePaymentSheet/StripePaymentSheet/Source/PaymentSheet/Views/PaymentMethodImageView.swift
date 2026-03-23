//
//  SavedPaymentMethodTypeImageView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import UIKit

/// A convenience UIImageView that displays the payment method image, handles the download if needed
class PaymentMethodImageView: UIImageView {
    enum ImageType {
        case collectionView(STPPaymentMethod, UIUserInterfaceStyle, PaymentSheet.Appearance.IconStyle)
        case collectionViewApplePay(UIUserInterfaceStyle, PaymentSheet.Appearance.IconStyle)
        case collectionViewLink(UIUserInterfaceStyle, PaymentSheet.Appearance.IconStyle)
        case rowButton(STPPaymentMethod, PaymentSheet.Appearance.IconStyle)
    }
    var imageType: ImageType?

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

    func set(_ imageType: ImageType) {
        self.imageType = imageType
        updateImage()
    }

    func updateImage() {
        guard let imageType else {
            return
        }
        switch imageType {
        case .collectionView(let paymentMethod, let overrideUserInterfaceStyle, let iconStyle):
            let image = paymentMethod.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle, iconStyle: iconStyle) { [weak self] image in
                DispatchQueue.main.async {
                    self?.setImage(image)
                }
            }
            setImage(image)
        case .collectionViewApplePay(let overrideUserInterfaceStyle, let iconStyle):
            let image = PaymentOption.applePay.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle, iconStyle: iconStyle)
            setImage(image)
        case .collectionViewLink(let overrideUserInterfaceStyle, let iconStyle):
            let image = PaymentOption.link(option: .wallet).makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle, iconStyle: iconStyle)
            setImage(image)
        case .rowButton(let paymentMethod, let iconStyle):
            let image = paymentMethod.makeSavedPaymentMethodRowImage(iconStyle: iconStyle) { [weak self] image in
                DispatchQueue.main.async {
                    self?.setImage(image)
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
