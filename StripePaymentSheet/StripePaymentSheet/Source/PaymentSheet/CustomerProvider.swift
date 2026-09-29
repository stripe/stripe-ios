//
//  CustomerProvider.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/27/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Provides a common view of customer data and capabilities across PaymentSheet integrations.
struct CustomerProvider {

    private enum Backing {

        case customer(PaymentSheet.CustomerConfiguration?)
        case checkoutSession(CheckoutController.Session)
    }

    private let backing: Backing

    init(customer: PaymentSheet.CustomerConfiguration?) {
        backing = .customer(customer)
    }

    init(checkoutSession: CheckoutController.Session) {
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

    var hasCustomer: Bool {
        return customerID != nil
    }

    enum Error: Swift.Error {

        case missingCustomerID
        case missingEphemeralKey
        case missingUpdatedPaymentMethod
    }

    var email: String? {
        guard case .checkoutSession(let session) = backing else {
            return nil
        }
        return session.customer?.email ?? session.email
    }

    var analyticValue: String? {
        switch backing {
        case .customer(let customer):
            return customer?.customerAccessProvider.analyticValue
        case .checkoutSession:
            return "checkout_session"
        }
    }

    var usesCustomerSession: Bool {
        guard case .customer(let customer) = backing,
              case .customerSession = customer?.customerAccessProvider else {
            return false
        }
        return true
    }

    var legacyEphemeralKeyCredentials: (customerID: String, ephemeralKeySecret: String)? {
        guard case .customer(let customer) = backing,
              let customer,
              case .legacyCustomerEphemeralKey(let ephemeralKeySecret) = customer.customerAccessProvider else {
            return nil
        }
        return (customer.id, ephemeralKeySecret)
    }

    var supportsLinkSetupFutureUsage: Bool {
        return usesCustomerSession
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

    func ephemeralKeySecret(basedOn elementsSession: STPElementsSession?) -> String? {
        guard case .customer(let customer) = backing else {
            return nil
        }
        return customer?.ephemeralKeySecret(basedOn: elementsSession)
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

    func savePaymentMethodConsentBehavior(
        elementsSession: STPElementsSession
    ) -> PaymentSheetFormFactory.SavePaymentMethodConsentBehavior {
        switch backing {
        case .checkoutSession(let session):
            guard hasCustomer, session.savedPaymentMethodsOfferSave?.enabled == true else {
                return .paymentSheetWithCheckoutSessionPaymentMethodSaveDisabled
            }
            return .paymentSheetWithCheckoutSessionPaymentMethodSaveEnabled
        case .customer:
            return elementsSession.savePaymentMethodConsentBehavior
        }
    }

    func allowsPaymentMethodRemoval(elementsSession: STPElementsSession) -> Bool {
        switch backing {
        case .checkoutSession(let session):
            return session.customer?.canDetachPaymentMethod ?? false
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

    @MainActor
    func update(
        paymentMethod: STPPaymentMethod,
        with updateParams: STPPaymentMethodUpdateParams,
        elementsSession: STPElementsSession,
        apiClient: STPAPIClient
    ) async throws -> STPPaymentMethod {
        let updatedPaymentMethod: STPPaymentMethod
        switch backing {
        case .checkoutSession(let session):
            let billing = CheckoutController.PaymentMethodBillingDetails(updateParams.billingDetails)
            let expiry = CheckoutController.PaymentMethodExpiryDetails(updateParams.card)
            guard billing != nil || expiry != nil else {
                throw PaymentSheetError.unknown(
                    debugDescription: "Tried to update a payment method without billing details or expiry details."
                )
            }
            let updatedSession = try await apiClient.updatePaymentMethod(
                paymentMethod.stripeId,
                inCheckoutSession: session.id,
                billingDetails: billing,
                expiryDetails: expiry
            )
            guard let paymentMethod = updatedSession.customer?.paymentMethods.first(where: {
                $0.stripeId == paymentMethod.stripeId
            }) else {
                throw Error.missingUpdatedPaymentMethod
            }
            updatedPaymentMethod = paymentMethod
        case .customer:
            guard let ephemeralKey = ephemeralKeySecret(basedOn: elementsSession) else {
                throw Error.missingEphemeralKey
            }
            updatedPaymentMethod = try await apiClient.updatePaymentMethod(
                with: paymentMethod.stripeId,
                paymentMethodUpdateParams: updateParams,
                ephemeralKeySecret: ephemeralKey
            )
        }
        updatedPaymentMethod.updateLocalFields(from: paymentMethod)
        return updatedPaymentMethod
    }

    @MainActor
    @discardableResult
    func detach(
        paymentMethod: STPPaymentMethod,
        elementsSession: STPElementsSession,
        apiClient: STPAPIClient
    ) -> Bool {
        switch backing {
        case .checkoutSession(let session):
            Task {
                try? await apiClient.detachPaymentMethod(
                    paymentMethod.stripeId,
                    fromCheckoutSession: session.id
                )
            }
            return true
        case .customer(let customer):
            guard let customer,
                  let ephemeralKey = ephemeralKeySecret(basedOn: elementsSession) else {
                return false
            }
            switch customer.customerAccessProvider {
            case .customerSession(let clientSecret):
                if paymentMethod.type == .card {
                    apiClient.detachPaymentMethodRemoveDuplicates(
                        paymentMethod.stripeId,
                        customerId: customer.id,
                        fromCustomerUsing: ephemeralKey,
                        withCustomerSessionClientSecret: clientSecret
                    ) { _ in }
                } else {
                    apiClient.detachPaymentMethod(
                        paymentMethod.stripeId,
                        fromCustomerUsing: ephemeralKey,
                        withCustomerSessionClientSecret: clientSecret
                    ) { _ in }
                }
            case .legacyCustomerEphemeralKey:
                apiClient.detachPaymentMethod(
                    paymentMethod.stripeId,
                    fromCustomerUsing: ephemeralKey
                ) { _ in }
            }
            return true
        }
    }

    @MainActor
    func setAsDefaultPaymentMethod(
        _ paymentMethodID: String,
        elementsSession: STPElementsSession,
        apiClient: STPAPIClient
    ) async throws -> STPCustomer {
        guard let ephemeralKey = ephemeralKeySecret(basedOn: elementsSession) else {
            throw Error.missingEphemeralKey
        }
        guard let customerID else {
            throw Error.missingCustomerID
        }
        return try await apiClient.setAsDefaultPaymentMethod(
            paymentMethodID,
            for: customerID,
            using: ephemeralKey
        )
    }
}
