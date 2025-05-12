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
    public static func decoded(
        fromAPIResponse response: [AnyHashable: Any]?,
        enableLinkInSPM: Bool
    ) -> ElementsCustomer? {
        guard let response else {
            return nil
        }

        let paymentMethods = Self.parsePaymentMethods(
            from: response,
            enableLinkInSPM: enableLinkInSPM && PaymentSheet.enableLinkInSPM
        )

        // Required fields
        guard let paymentMethods,
              let customerSessionDict = response["customer_session"] as? [AnyHashable: Any],
              let customerSession = CustomerSession.decoded(fromAPIResponse: customerSessionDict)
        else {
            return nil
        }

        // Optional
        let defaultPaymentMethod = response["default_payment_method"] as? String
        return ElementsCustomer(
            paymentMethods: paymentMethods,
            defaultPaymentMethod: defaultPaymentMethod,
            customerSession: customerSession
        )
    }

    private static func parsePaymentMethods(from response: [AnyHashable: Any], enableLinkInSPM: Bool) -> [STPPaymentMethod]? {
        guard let paymentMethodsArray = selectPaymentMethods(from: response, enableLinkInSPM: enableLinkInSPM) else {
            return nil
        }

        var paymentMethods: [STPPaymentMethod] = []
        for json in paymentMethodsArray {
            if enableLinkInSPM {
                if let paymentMethodWithLinkDetails = PaymentMethodWithLinkDetails.decodedObject(fromAPIResponse: json) {
                    let paymentMethod = paymentMethodWithLinkDetails.paymentMethod
                    if let cardDetails = paymentMethodWithLinkDetails.linkDetails?.cardDetails {
                        paymentMethod.setLinkPaymentDetails(from: cardDetails)
                    }
                    paymentMethods.append(paymentMethod)
                }
            } else {
                if let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: json) {
                    paymentMethods.append(paymentMethod)
                }
            }
        }

        return paymentMethods
    }

    private static func selectPaymentMethods(from response: [AnyHashable: Any], enableLinkInSPM: Bool) -> [[AnyHashable: Any]]? {
        let paymentMethodsArray: [[AnyHashable: Any]]?
        if enableLinkInSPM {
            paymentMethodsArray = response["payment_methods_with_link_details"] as? [[AnyHashable: Any]]
        } else {
            paymentMethodsArray = response["payment_methods"] as? [[AnyHashable: Any]]
        }
        return paymentMethodsArray
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

    func setLinkPaymentDetails(from cardDetails: ConsumerPaymentDetails.Details.Card) {
        self.linkPaymentDetails = LinkPaymentDetails(
            expMonth: cardDetails.expiryMonth,
            expYear: cardDetails.expiryYear,
            last4: cardDetails.last4,
            brand: cardDetails.stpBrand
        )
    }
}
