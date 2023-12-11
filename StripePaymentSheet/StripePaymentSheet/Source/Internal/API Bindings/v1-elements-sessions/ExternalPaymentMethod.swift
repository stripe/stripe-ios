//
//  ExternalPaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/12/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// ViewModel-like information for displaying external payment methods (EPMs), delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/elements/api/private/struct/external_payment_method_data.rb
struct ExternalPaymentMethod: Decodable, Equatable, Hashable {
    /// The type of the external payment method. e.g. `"external_foopay"`
    /// These match the strings specified by the merchant in `ExternalPaymentMethodConfiguration`.
    let type: String
    /// A localized label for the payment method e.g. "FooPay"
    let label: String
    /// URL of a 48x pixel tall, variable width PNG representing the payment method suitable for display against a light background color.
    let lightImageUrl: URL
    /// URL of a 48x pixel, variable width tall PNG representing the payment method suitable for display against a dark background color. If `nil`, use `lightImageUrl` instead.
    let darkImageUrl: URL?

    /// Helper method to decode the `v1/elements/sessions` response's `external_payment_methods_data` hash.
    /// - Parameter response: The value of the `external_payment_methods_data` key in the `v1/elements/sessions` response.
    public static func decoded(fromAPIResponse response: [[AnyHashable: Any]]?) -> [ExternalPaymentMethod]? {
        guard let response else {
            return nil
        }
        do {
            return try response.map { dict in
                let data = try JSONSerialization.data(withJSONObject: dict)
                return try StripeJSONDecoder().decode(ExternalPaymentMethod.self, from: data)
            }
        } catch {
            return nil
        }
    }
}
