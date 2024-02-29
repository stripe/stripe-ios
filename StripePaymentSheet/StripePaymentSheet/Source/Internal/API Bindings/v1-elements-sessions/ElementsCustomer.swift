//
//  ElementsCustomer.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// ViewModel-like information for displaying customer information, delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/elements/api/private/struct/elements_customer.rb
struct ElementsCustomer: Equatable, Hashable {

    let paymentMethods: [STPPaymentMethod]
    let defaultPaymentMethod: String?
//    let customerSession:
//    let darkImageUrl: URL?

    /// Helper method to decode the `v1/elements/sessions` response's `customer` hash.
    /// - Parameter response: The value of the `customer` key in the `v1/elements/sessions` response.
    public static func decoded(fromAPIResponse response: [AnyHashable: Any]?) -> ElementsCustomer? {
        // Required fields
        guard let response,
              let paymentMethodsArray = response["payment_methods"] as? [[AnyHashable: Any]]
            //TODO
              //payment_methods_with_link_details
              //customer_ssion
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
        return ElementsCustomer(paymentMethods: paymentMethods, defaultPaymentMethod: defaultPaymentMethod)
    }
}
