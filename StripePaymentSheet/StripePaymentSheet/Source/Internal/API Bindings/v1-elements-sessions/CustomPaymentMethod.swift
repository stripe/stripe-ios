//
//  CustomPaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/5/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// ViewModel-like information for displaying custom payment methods (CPMs), delivered in the `v1/elements/sessions` response.
struct CustomPaymentMethod: Decodable {
    /// The display name of this custom payment method as defined in the Stripe dashboard
    let displayName: String?

    /// The type (id) of the custom payment method. e.g. `"cpmt_..."`
    /// These match the ids specified by the merchant in `CustomPaymentMethodConfiguration`.
    let type: String

    /// URL of a 48x pixel tall, variable width PNG representing the payment method.
    let logoUrl: URL?

    /// If true, this custom payment method was created using a preset in the Stripe dashboard
    let isPreset: Bool?

    /// If there was an error fetching this custom payment method this will be populated with the error
    let error: String?

    /// Helper method to decode the `v1/elements/sessions` response's `custom_payment_methods_data` hash.
    /// - Parameter response: The value of the `custom_payment_methods_data` key in the `v1/elements/sessions` response.
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
