//
//  PaymentMethodTypeImageView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/13/24.
//

@_spi(STP) import StripeUICore
import UIKit

/// A convenience UIImageView that displays the payment method types image, handles the download, and automatically updates its image for dark mode.
class PaymentMethodTypeImageView: UIImageView {
    let paymentMethodType: PaymentSheet.PaymentMethodType
    let contrastMatchingColor: UIColor
    let currency: String?

    /// Initializes a PaymentMethodTypeImageView with the specified payment method type and a color to match contrast.
    ///
    /// - Parameters:
    ///   - paymentMethodType: The type of payment method whose icon is displayed.
    ///   - contrastMatchingColor: The color used to determine the icon's tint, internally rounded to black or white to ensure optimal visibility. For example, you might pass in the color of the text label adjacent to the icon so they share the same contrast characteristics.
    init(paymentMethodType: PaymentSheet.PaymentMethodType, contrastMatchingColor: UIColor, currency: String?) {
        self.paymentMethodType = paymentMethodType
        self.contrastMatchingColor = contrastMatchingColor
        self.currency = currency
        super.init(image: nil)
        self.contentMode = .scaleAspectFit
        updateImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateImage()
    }
#endif

    func updateImage() {
        // Unfortunately the DownloadManager API returns either a placeholder image _or_ the actual image
        // Set the image now...
        let image = paymentMethodType.makeImage(forDarkBackground: contrastMatchingColor.roundToBlackOrWhite == .white, currency: currency) { [weak self] image in
            DispatchQueue.main.async {
                // ...and set it again if the callback is called with a downloaded image
                self?.setImage(image)
            }
        }
        setImage(image)
    }

    func setImage(_ image: UIImage) {
        if self.paymentMethodType.iconRequiresTinting  {
            self.image = image.withRenderingMode(.alwaysTemplate)
            tintColor = contrastMatchingColor.roundToBlackOrWhite
        } else {
            self.image = image
            tintColor = nil
        }
    }
}
