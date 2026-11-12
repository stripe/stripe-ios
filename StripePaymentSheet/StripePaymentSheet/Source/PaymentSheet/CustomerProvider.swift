//
//  CustomerProvider.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/27/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// Provides a common view of customer data and capabilities across PaymentSheet integrations.
struct CustomerProvider {

    private enum Backing {

        case customer(PaymentSheet.CustomerConfiguration?)
        case checkoutSession(CheckoutElementsController.Session)
    }

    private let backing: Backing

    init(customer: PaymentSheet.CustomerConfiguration?) {
        backing = .customer(customer)
    }

    init(checkoutSession: CheckoutElementsController.Session) {
        backing = .checkoutSession(checkoutSession)
    }

    var customerID: String? {
        switch backing {
        case .customer(let customer):
            return customer?.id
        case .checkoutSession(let session):
            return session.customer?.id
        }
    }

    /// Resolves the customer ID, falling back to the customer resolved server-side from the
    /// `elementsSession`'s CustomerSession when the configuration didn't provide one explicitly.
    func customerID(elementsSession: STPElementsSession?) -> String? {
        switch backing {
        case .customer(let customer):
            return customer?.resolvedID(elementsSession: elementsSession)
        case .checkoutSession(let session):
            return session.customer?.id
        }
    }

    var hasCustomer: Bool {
        return customerID != nil
    }

    var legacyEphemeralKeyCredentials: (customerID: String, ephemeralKeySecret: String)? {
        guard case .customer(let customer) = backing,
              let customer,
              let id = customer.id,
              case .legacyCustomerEphemeralKey(let ephemeralKeySecret) = customer.customerAccessProvider else {
            return nil
        }
        return (id, ephemeralKeySecret)
    }

    func savedPaymentMethods(
        elementsSession: STPElementsSession,
        prefetchedPaymentMethods: [STPPaymentMethod]?
    ) -> [STPPaymentMethod]? {
        switch backing {
        case .customer(let customer):
            switch customer?.customerAccessProvider {
            case .legacyCustomerEphemeralKey:
                return prefetchedPaymentMethods
            case .customerSession:
                return elementsSession.customer?.paymentMethods
            case nil:
                return nil
            }
        case .checkoutSession(let session):
            return session.customer?.paymentMethods
        }
    }

    var usesCustomerSession: Bool {
        guard case .customer(let customer) = backing,
              case .customerSession = customer?.customerAccessProvider else {
            return false
        }
        return true
    }

    func addElementsSessionParams(to parameters: inout [String: Any]) {
        guard case .customer(let customer) = backing else {
            return
        }
        switch customer?.customerAccessProvider {
        case .legacyCustomerEphemeralKey(let ephemeralKeySecret):
            parameters["legacy_customer_ephemeral_key"] = ephemeralKeySecret
        case .customerSession(let clientSecret):
            parameters["customer_session_client_secret"] = clientSecret
        case nil:
            break
        }
    }

    var analyticValue: String? {
        switch backing {
        case .customer(let customer):
            return customer?.customerAccessProvider.analyticValue
        case .checkoutSession:
            return "checkout_session"
        }
    }

    func allowsPaymentMethodRemoval(elementsSession: STPElementsSession) -> Bool {
        switch backing {
        case .checkoutSession(let session):
            return session.canDetachPaymentMethod
        case .customer:
            return elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        }
    }

    func allowsPaymentMethodUpdate(elementsSession: STPElementsSession) -> Bool {
        switch backing {
        case .checkoutSession:
            return true
        case .customer:
            return elementsSession.paymentMethodUpdateForPaymentSheet
        }
    }
}
