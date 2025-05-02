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
              let paymentMethodsWithLinkDetailsArray = response["payment_methods_with_link_details"] as? [[AnyHashable: Any]],
              let customerSessionDict = response["customer_session"] as? [AnyHashable: Any],
              let customerSession = CustomerSession.decoded(fromAPIResponse: customerSessionDict)
        else {
            return nil
        }

        var paymentMethods: [STPPaymentMethod] = []
        for json in paymentMethodsWithLinkDetailsArray {
            if let paymentMethodWithLinkDetails = PaymentMethodWithLinkDetails.decodedObject(fromAPIResponse: json) {
                let paymentMethod = paymentMethodWithLinkDetails.paymentMethod
                paymentMethod.setLinkPaymentDetails(from: paymentMethodWithLinkDetails.linkDetails)
                paymentMethods.append(paymentMethod)
            }
        }

        // Optional
        let defaultPaymentMethod = response["default_payment_method"] as? String
        return ElementsCustomer(
            paymentMethods: paymentMethods,
            defaultPaymentMethod: defaultPaymentMethod,
            customerSession: customerSession
        )
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

private extension ConsumerPaymentDetails {

    var cardDetails: ConsumerPaymentDetails.Details.Card? {
        guard case .card(let cardDetails) = details else {
            return nil
        }

        return cardDetails
    }
}

private extension STPPaymentMethod {

    func setLinkPaymentDetails(from paymentDetails: ConsumerPaymentDetails?) {
        self.linkPaymentDetails = paymentDetails?.cardDetails.flatMap {
            LinkPaymentDetails(
                last4: $0.last4,
                brand: $0.stpBrand
            )
        }
    }
}
