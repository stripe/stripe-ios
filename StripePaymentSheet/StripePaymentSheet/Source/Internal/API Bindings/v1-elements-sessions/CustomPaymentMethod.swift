//
//  CustomPaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/5/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

struct CustomPaymentMethod: Decodable, Equatable, Hashable {
    /// The type of the external payment method. e.g. `"external_foopay"`
    /// These match the strings specified by the merchant in `ExternalPaymentMethodConfiguration`.
    let displayName: String
    /// A localized label for the payment method e.g. "FooPay"
    let type: String

    let logoUrl: URL

    /// Helper method to decode the `v1/elements/sessions` response's `external_payment_methods_data` hash.
    /// - Parameter response: The value of the `external_payment_methods_data` key in the `v1/elements/sessions` response.
    public static func decoded(fromAPIResponse response: [[AnyHashable: Any]]?) -> [CustomPaymentMethod]? {
        guard let response else {
            return nil
        }
        do {
            return try response.map { dict in
                let data = try JSONSerialization.data(withJSONObject: dict)
                return try StripeJSONDecoder().decode(CustomPaymentMethod.self, from: data)
            }
        } catch {
            return nil
        }
    }
}
