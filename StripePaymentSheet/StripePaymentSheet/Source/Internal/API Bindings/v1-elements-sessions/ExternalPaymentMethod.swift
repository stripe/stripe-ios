//
//  ExternalPaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/12/23.
//

import Foundation
@_spi(STP) import StripePayments

/// ViewModel-like information for displaying external payment methods (EPMs)
struct ExternalPaymentMethod: Decodable, Equatable, Hashable {
    /// The type of the external payment method. e.g. `"external_foopay"`
    /// These match the strings specified by the merchant in `ExternalPaymentMethodConfiguration`.
    let type: String
    /// A localized label for the payment method e.g. "FooPay"
    let localizedLabel: String

    // TODO: Temporary shim while we only support hardcoded "external_paypal"
    static func makeExternalPaypal() -> ExternalPaymentMethod {
        return .init(
            type: "external_paypal",
            localizedLabel: STPPaymentMethodType.payPal.displayName
        )
    }
}
