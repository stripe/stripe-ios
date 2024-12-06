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
        // to test default payment methods reading from back end, hard-code a valid default payment method
        // later, when API calls to get and update default payment method are available, that will no longer be needed
//        let defaultPaymentMethod = response["default_payment_method"] as? String
        let defaultPaymentMethod = "pm_1QT9oDLu5o3P18ZpuYfoTQIX"
        return ElementsCustomer(paymentMethods: paymentMethods, defaultPaymentMethod: defaultPaymentMethod, customerSession: customerSession)
    }

    static func getDefaultPaymentMethod(from customer: ElementsCustomer?) -> STPPaymentMethod? {
        guard let customer = customer else { return nil }
        return customer.paymentMethods.first { $0.stripeId == customer.defaultPaymentMethod }
    }
}
