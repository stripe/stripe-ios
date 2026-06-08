//
//  PaymentSheetFormFactory+AfterpayClearpay.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeAfterpayClearpayHeader() -> SubtitleElement {
        if let header = makeBNPLHeader() {
            // Use the shared BNPL header when header content is available.
            return header
        } else {
            // Fall back to the legacy Afterpay/Clearpay-specific header UI.
            return SubtitleElement(
                view: AfterpayPriceBreakdownView(
                    currency: currency,
                    appearance: configuration.appearance
                ),
                isHorizontalMode: paymentMethodOrientation == .horizontal
            )
        }
    }
}
