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

    enum Source: Equatable {
        case none
        case legacyEphemeralKey
        case customerSession
        case checkoutSession
    }

    enum Error: Swift.Error {
        case missingCustomerID
        case missingEphemeralKey
        case missingUpdatedPaymentMethod
    }

    struct SaveConsent: Equatable {
        let enabled: Bool
        let initiallyChecked: Bool
    }

    private enum Backing {
        case none
        case legacyEphemeralKey(customerID: String?, ephemeralKeySecret: String)
        case customerSession(customerID: String?, clientSecret: String)
        case checkoutSession(CheckoutController.Session)
    }

    private let backing: Backing

    init(customer: PaymentSheet.CustomerConfiguration?) {
        guard let customer else {
            backing = .none
            return
        }

        switch customer.customerAccessProvider {
        case .legacyCustomerEphemeralKey(let ephemeralKeySecret):
            backing = .legacyEphemeralKey(
                customerID: customer.id,
                ephemeralKeySecret: ephemeralKeySecret
            )
        case .customerSession(let clientSecret):
            backing = .customerSession(
                customerID: customer.id,
                clientSecret: clientSecret
            )
        }
    }

    init(checkoutSession: CheckoutController.Session) {
        backing = .checkoutSession(checkoutSession)
    }

    init(
        customerAccessProvider: PaymentSheet.CustomerAccessProvider?,
        customerID: String? = nil
    ) {
        switch customerAccessProvider {
        case .legacyCustomerEphemeralKey(let ephemeralKeySecret):
            backing = .legacyEphemeralKey(
                customerID: customerID,
                ephemeralKeySecret: ephemeralKeySecret
            )
        case .customerSession(let clientSecret):
            backing = .customerSession(
                customerID: customerID,
                clientSecret: clientSecret
            )
        case nil:
            backing = .none
        }
    }

    var source: Source {
        switch backing {
        case .none:
            return .none
        case .legacyEphemeralKey:
            return .legacyEphemeralKey
        case .customerSession:
            return .customerSession
        case .checkoutSession:
            return .checkoutSession
        }
    }

    var customerID: String? {
        switch backing {
        case .none:
            return nil
        case .legacyEphemeralKey(let customerID, _), .customerSession(let customerID, _):
            return customerID
        case .checkoutSession(let session):
            return session.customer?.id
        }
    }

    var hasCustomer: Bool {
        return customerID != nil
    }

    var email: String? {
        guard case .checkoutSession(let session) = backing else {
            return nil
        }
        return session.customer?.email ?? session.email
    }

    var name: String? {
        guard case .checkoutSession(let session) = backing else {
            return nil
        }
        return session.customer?.name
    }

    var phone: String? {
        guard case .checkoutSession(let session) = backing else {
            return nil
        }
        return session.customer?.phone
    }

    var saveConsent: SaveConsent? {
        guard case .checkoutSession(let session) = backing,
              let offerSave = session.savedPaymentMethodsOfferSave else {
            return nil
        }
        return SaveConsent(
            enabled: offerSave.enabled,
            initiallyChecked: offerSave.status == .accepted
        )
    }

    var analyticValue: String? {
        switch source {
        case .none:
            return nil
        case .legacyEphemeralKey:
            return "legacy"
        case .customerSession:
            return "customer_session"
        case .checkoutSession:
            return "checkout_session"
        }
    }

    var customerSessionClientSecret: String? {
        guard case .customerSession(_, let clientSecret) = backing else {
            return nil
        }
        return clientSecret
    }

    var usesCustomerSession: Bool {
        return source == .customerSession
    }

    var legacyEphemeralKeyCredentials: (customerID: String, ephemeralKeySecret: String)? {
        guard case .legacyEphemeralKey(let customerID, let ephemeralKeySecret) = backing,
              let customerID else {
            return nil
        }
        return (customerID, ephemeralKeySecret)
    }

    var supportsLinkSetupFutureUsage: Bool {
        return source == .customerSession
    }

    func addElementsSessionParams(to parameters: inout [String: Any]) {
        switch backing {
        case .legacyEphemeralKey(_, let ephemeralKeySecret):
            parameters["legacy_customer_ephemeral_key"] = ephemeralKeySecret
        case .customerSession(_, let clientSecret):
            parameters["customer_session_client_secret"] = clientSecret
        case .none, .checkoutSession:
            break
        }
    }

    func ephemeralKeySecret(basedOn elementsSession: STPElementsSession?) -> String? {
        switch backing {
        case .legacyEphemeralKey(_, let ephemeralKeySecret):
            return ephemeralKeySecret
        case .customerSession:
            return elementsSession?.customer?.customerSession.apiKey
        case .none, .checkoutSession:
            return nil
        }
    }

    func savedPaymentMethods(
        elementsSession: STPElementsSession,
        prefetchedPaymentMethods: [STPPaymentMethod]?
    ) -> [STPPaymentMethod]? {
        switch backing {
        case .none:
            return nil
        case .legacyEphemeralKey:
            return prefetchedPaymentMethods
        case .customerSession:
            return elementsSession.customer?.paymentMethods
        case .checkoutSession(let session):
            return session.customer?.paymentMethods
        }
    }

    func savePaymentMethodConsentBehavior(
        elementsSession: STPElementsSession
    ) -> PaymentSheetFormFactory.SavePaymentMethodConsentBehavior {
        switch backing {
        case .checkoutSession:
            guard hasCustomer, saveConsent?.enabled == true else {
                return .paymentSheetWithCheckoutSessionPaymentMethodSaveDisabled
            }
            return .paymentSheetWithCheckoutSessionPaymentMethodSaveEnabled
        case .none, .legacyEphemeralKey, .customerSession:
            return elementsSession.savePaymentMethodConsentBehavior
        }
    }

    func allowsPaymentMethodRemoval(elementsSession: STPElementsSession) -> Bool {
        switch backing {
        case .checkoutSession(let session):
            return session.customer?.canDetachPaymentMethod ?? false
        case .none, .legacyEphemeralKey, .customerSession:
            return elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        }
    }

    func allowsPaymentMethodUpdate(elementsSession: STPElementsSession) -> Bool {
        switch backing {
        case .checkoutSession:
            return true
        case .none, .legacyEphemeralKey, .customerSession:
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
        case .none, .legacyEphemeralKey, .customerSession:
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
        case .customerSession(let customerID, let clientSecret):
            guard let ephemeralKey = ephemeralKeySecret(basedOn: elementsSession) else {
                return false
            }
            guard let customerID else {
                return false
            }
            if paymentMethod.type == .card {
                apiClient.detachPaymentMethodRemoveDuplicates(
                    paymentMethod.stripeId,
                    customerId: customerID,
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
            return true
        case .legacyEphemeralKey:
            guard let ephemeralKey = ephemeralKeySecret(basedOn: elementsSession) else {
                return false
            }
            apiClient.detachPaymentMethod(
                paymentMethod.stripeId,
                fromCustomerUsing: ephemeralKey
            ) { _ in }
            return true
        case .none:
            return false
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
