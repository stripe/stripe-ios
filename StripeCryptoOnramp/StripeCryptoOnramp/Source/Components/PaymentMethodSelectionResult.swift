//
//  PaymentMethodSelectionResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/11/25.
//

import Foundation
import UIKit

/// The result after a user has been presented with the payment method selector.
@_spi(CryptoOnrampSDKPreview)
public enum PaymentMethodSelectionResult {

    /// Represents a payment method selected by the user.
    public struct PaymentMethodPreview {

        /// The icon to render in your screen.
        public let icon: UIImage

        /// The label to render in your screen.
        public let label: String

        /// Details about the selected payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
        public let sublabel: String?
    }

    /// The user has completed selection of a payment method. The payment method preview is attached.
    case completed(PaymentMethodPreview)

    /// The user did not complete payment method selection.
    case canceled
}
