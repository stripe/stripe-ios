//
//  ElementsCustomer.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Elements Customer, delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/elements/api/resources/elements_customer_resource.rb
struct ElementsCustomer: Equatable, Hashable {

    let paymentMethods: [STPPaymentMethod]
    let defaultPaymentMethod: String?
    let customerSession: CustomerSession

    /// Helper method to decode the `v1/elements/sessions` response's `customer` hash.
    /// - Parameter response: The value of the `customer` key in the `v1/elements/sessions` response.
    public static func decoded(fromAPIResponse response: [AnyHashable: Any]?) -> ElementsCustomer? {
        // Required fields
        guard let response,
              let paymentMethodsArray = response["payment_methods"] as? [[AnyHashable: Any]],
              let customerSessionDict = response["customer_session"] as? [AnyHashable: Any],
              let customerSession = CustomerSession.decoded(fromAPIResponse: customerSessionDict)
        else {
            return nil
        }

        var paymentMethods: [STPPaymentMethod] = []
        for paymentMethodJSON in paymentMethodsArray {
            let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethodJSON)
            if let paymentMethod = paymentMethod {
                paymentMethods.append(paymentMethod)
            }
        }

        // Optional
        let defaultPaymentMethod = response["default_payment_method"] as? String
        return ElementsCustomer(paymentMethods: paymentMethods, defaultPaymentMethod: defaultPaymentMethod, customerSession: customerSession)
    }

    func getDefaultPaymentMethod() -> STPPaymentMethod? {
        return paymentMethods.first { $0.stripeId == defaultPaymentMethod }
    }

    func getDefaultOrFirstPaymentMethod() -> STPPaymentMethod? {
        // if customer has a default payment method from the elements session, return the default payment method
        // otherwise, return the first payment method from the customer's list of saved payment methods
        return getDefaultPaymentMethod() ?? paymentMethods.first
    }
}
