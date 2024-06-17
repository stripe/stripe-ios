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
    var resolvedBackgroundColor: UIColor? {
        return backgroundColor?.resolvedColor(with: traitCollection)
    }

    init(paymentMethodType: PaymentSheet.PaymentMethodType, backgroundColor: UIColor) {
        self.paymentMethodType = paymentMethodType
        super.init(image: nil)
        self.backgroundColor = backgroundColor
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
        let image = paymentMethodType.makeImage(forDarkBackground: resolvedBackgroundColor?.contrastingColor == .white) { [weak self] image in
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
            tintColor = resolvedBackgroundColor?.contrastingColor
        } else {
            self.image = image
            tintColor = nil
        }
    }
}
