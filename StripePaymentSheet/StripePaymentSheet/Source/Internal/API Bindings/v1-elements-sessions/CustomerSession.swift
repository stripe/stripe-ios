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
    let paymentSheetComponent: PaymentSheetComponent?

    /// Helper method to decode the `v1/elements/sessions` response's `external_payment_methods_data` hash.
    /// - Parameter response: The value of the `external_payment_methods_data` key in the `v1/elements/sessions` response.
    public static func decoded(fromAPIResponse response: [AnyHashable: Any]?) -> CustomerSession? {
        guard let response,
              let id = response["id"] as? String,
              let liveMode = response["livemode"] as? Bool,
              let apiKey = response["api_key"] as? String,
              let apiKeyExpiry = response["api_key_expiry"] as? Int,
              let customer = response["customer"] as? String,
              let componentsDict = response["components"] as? [AnyHashable: Any] else {
            return nil
        }
        guard let paymentSheetDict = componentsDict["payment_sheet"] as? [AnyHashable: Any],
              let paymentSheetEnabled = paymentSheetDict["enabled"] as? Bool else {
            return nil
        }

        var paymentSheetComponent: PaymentSheetComponent?
        if paymentSheetEnabled {
            guard let paymentSheetFeaturesDict = paymentSheetDict["features"] as? [AnyHashable: Any],
                  let paymentMethodSave = paymentSheetFeaturesDict["payment_method_save"] as? String,
                  let paymentMethodRemove = paymentSheetFeaturesDict["payment_method_remove"] as? String else {
                return nil
            }
            paymentSheetComponent = PaymentSheetComponent(enabled: true,
                                                          features: PaymentSheetComponentFeature(paymentMethodSave: paymentMethodSave == "enabled",
                                                                                                 paymentMethodRemove: paymentMethodRemove == "enabled"))
        } else {
            paymentSheetComponent = PaymentSheetComponent(enabled: false, features: nil)
        }

        return CustomerSession(id: id, liveMode: liveMode, apiKey: apiKey, apiKeyExpiry: apiKeyExpiry, customer: customer, paymentSheetComponent: paymentSheetComponent)
    }
}

struct PaymentSheetComponent: Equatable, Hashable {
    let enabled: Bool
    let features: PaymentSheetComponentFeature?
}

struct PaymentSheetComponentFeature: Equatable, Hashable {
    let paymentMethodSave: Bool
    let paymentMethodRemove: Bool
}
