//
//  PaymentMethodDisplayData.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/11/25.
//

import Foundation
import UIKit

/// Represents the payment method currently selected by the user.
@_spi(CryptoOnrampSDKPreview)
public struct PaymentMethodDisplayData {

    /// The payment method icon to render in your screen.
    public let icon: UIImage

    /// The payment method label to render in your screen. For instance, `Link` or `Apple Pay`.
    public let label: String

    /// Details about the underlying payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
    public let sublabel: String?

    /// Creates a new instance of `PaymentMethodDisplayData`.
    /// - Parameters:
    ///   - icon: The payment method icon to render in your screen.
    ///   - label: The payment method label to render in your screen. For instance, `Link` or `Apple Pay`.
    ///   - sublabel: Details about the underlying payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
    public init(icon: UIImage, label: String, sublabel: String?) {
        self.icon = icon
        self.label = label
        self.sublabel = sublabel
    }
}
