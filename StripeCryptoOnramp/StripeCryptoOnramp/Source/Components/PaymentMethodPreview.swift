//
//  PaymentMethodPreview.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/11/25.
//

import Foundation
import UIKit

/// Represents the payment method currently selected by the user.
@_spi(CryptoOnrampSDKPreview)
public struct PaymentMethodPreview {

    /// The Link icon to render in your screen.
    public let icon: UIImage

    /// The Link label to render in your screen.
    public let label: String

    /// Details about the selected Link payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
    public let sublabel: String?

    /// Creates a new instance of `PaymentMethodPreview`.
    /// - Parameters:
    ///   - icon: The Link icon to render in your screen.
    ///   - label: The Link label to render in your screen.
    ///   - sublabel: Details about the selected Link payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
    public init(icon: UIImage, label: String, sublabel: String?) {
        self.icon = icon
        self.label = label
        self.sublabel = sublabel
    }
}

