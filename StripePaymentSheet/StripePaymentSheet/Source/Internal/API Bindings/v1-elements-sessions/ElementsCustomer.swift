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
            enableLinkInSPM: enableLinkInSPM
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
                    if let linkDetails = paymentMethodWithLinkDetails.linkDetails {
                        paymentMethod.setLinkPaymentDetails(from: linkDetails)
                    } else {
                        paymentMethod.isLinkPassthroughMode = paymentMethodWithLinkDetails.isLinkOrigin
                    }
                    paymentMethods.append(paymentMethod)
                }
            } else {
                if let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: json) {
                    paymentMethod.isLinkPassthroughMode = paymentMethod.card?.wallet?.type == .link
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

private extension STPPaymentMethod {

    func setLinkPaymentDetails(from paymentDetails: ConsumerPaymentDetails) {
        switch paymentDetails.details {
        case .card(let cardDetails):
            let linkCardDetails = LinkPaymentDetails.Card(from: cardDetails, nickname: paymentDetails.nickname, paymentDetailsID: paymentDetails.stripeID)
            self.linkPaymentDetails = .card(linkCardDetails)
        case .bankAccount(let bankDetails):
            let bankAccount = LinkPaymentDetails.BankDetails(from: bankDetails, paymentDetailsID: paymentDetails.stripeID)
            self.linkPaymentDetails = .bankAccount(bankAccount)
        case .unparsable:
            break
        }
    }
}

private extension LinkPaymentDetails.BankDetails {
    init(from bankDetails: ConsumerPaymentDetails.Details.BankAccount, paymentDetailsID: String) {
        self = .init(
            id: paymentDetailsID,
            bankName: bankDetails.name,
            last4: bankDetails.last4
        )
    }
}

private extension LinkPaymentDetails.Card {
    init(from cardDetails: ConsumerPaymentDetails.Details.Card, nickname: String?, paymentDetailsID: String) {
        self = .init(
            id: paymentDetailsID,
            displayName: cardDetails.displayName(with: nickname),
            expMonth: cardDetails.expiryMonth,
            expYear: cardDetails.expiryYear,
            last4: cardDetails.last4,
            brand: cardDetails.stpBrand
        )
    }
}
