//
//  CustomerSession.swift
//  StripePaymentSheet
//

import Foundation

/// CustomerSession information, delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/api/lib/customer_session/resource/customer_session_client_resource.rb
struct CustomerSession: Equatable, Hashable {
    let id: String
    let liveMode: Bool
    let apiKey: String
    let apiKeyExpiry: Int
    let customer: String

    /// Helper method to decode the `v1/elements/sessions` response's `external_payment_methods_data` hash.
    /// - Parameter response: The value of the `external_payment_methods_data` key in the `v1/elements/sessions` response.
    public static func decoded(fromAPIResponse response: [AnyHashable: Any]?) -> CustomerSession? {
        guard let response,
              let id = response["id"] as? String,
              let liveMode = response["livemode"] as? Bool,
              let apiKey = response["api_key"] as? String,
              let apiKeyExpiry = response["api_key_expiry"] as? Int,
              let customer = response["customer"] as? String else {
            return nil
        }
        return CustomerSession(id: id, liveMode: liveMode, apiKey: apiKey, apiKeyExpiry: apiKeyExpiry, customer: customer)
    }
}
