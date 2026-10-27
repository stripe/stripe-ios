//
//  CustomerProvider.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/27/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Provides customer data, capabilities, and saved payment method operations across PaymentSheet integrations.
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

    var legacyEphemeralKeyCredentials: (customerID: String, ephemeralKeySecret: String)? {
        guard case .customer(let customer) = backing,
              let customer,
              case .legacyCustomerEphemeralKey(let ephemeralKeySecret) = customer.customerAccessProvider else {
            return nil
        }
        return (customer.id, ephemeralKeySecret)
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

    /// Resolves customer email for Link lookup. Callers apply their integration's explicit email/defaults first.
    func linkEmail(
        elementsSession: STPElementsSession? = nil,
        prefetchedEmail: String? = nil
    ) -> String? {
        if let prefetchedEmail {
            return prefetchedEmail
        }
        if case .checkoutSession(let session) = backing, let email = session.email {
            return email
        }
        // Keep the session fallback even when no customer is configured or the legacy fetch failed.
        return elementsSession?.customer?.email
    }

    /// Legacy integrations need a separate Customer request; other integrations include email in their session.
    @MainActor
    func prefetchLinkEmail(apiClient: STPAPIClient, loadTimings: PaymentSheetLoader.LoadTimings) async throws -> String? {
        guard let credentials = legacyEphemeralKeyCredentials else {
            return nil
        }
        loadTimings.logStart("retrieveCustomer")
        defer {
            loadTimings.logEnd("retrieveCustomer")
        }
        let customer = try await apiClient.retrieveCustomer(
            credentials.customerID,
            using: credentials.ephemeralKeySecret
        )
        return customer.email
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

    private enum Error: String, AnalyticLoggableError {

        case missingEphemeralKey
        case missingUpdatedPaymentMethod

        var analyticsErrorType: String {
            // Preserve the analytics identity used before these operations moved to the provider.
            return "StripePaymentSheet.SavedPaymentMethodManager.Error"
        }

        var analyticsErrorCode: String {
            return rawValue
        }

        var additionalNonPIIErrorDetails: [String: Any] {
            return [:]
        }
    }

    func ephemeralKeySecret(basedOn elementsSession: STPElementsSession?) -> String? {
        guard case .customer(let customer) = backing else {
            return nil
        }
        return customer?.ephemeralKeySecret(basedOn: elementsSession)
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
                let errorAnalytic = ErrorAnalytic(
                    event: .unexpectedPaymentSheetError,
                    error: Error.missingUpdatedPaymentMethod,
                    additionalNonPIIParams: ["payment_method_id": paymentMethod.stripeId]
                )
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                throw PaymentSheetError.unknown(
                    debugDescription: "Checkout session response didn't include the updated payment method."
                )
            }
            updatedPaymentMethod = paymentMethod
        case .customer:
            guard let ephemeralKey = ephemeralKeySecret(basedOn: elementsSession) else {
                logMissingEphemeralKey()
                throw PaymentSheetError.unknown(
                    debugDescription: "Failed to read ephemeral key while updating a payment method."
                )
            }
            updatedPaymentMethod = try await apiClient.updatePaymentMethod(
                with: paymentMethod.stripeId,
                paymentMethodUpdateParams: updateParams,
                ephemeralKeySecret: ephemeralKey
            )
        }
        // API responses don't contain the local Link details attached to the original method.
        updatedPaymentMethod.updateLocalFields(from: paymentMethod)
        return updatedPaymentMethod
    }

    @MainActor
    func detach(
        paymentMethod: STPPaymentMethod,
        elementsSession: STPElementsSession,
        apiClient: STPAPIClient
    ) {
        // Removal is optimistic; callers update their UI without waiting for the network response.
        switch backing {
        case .checkoutSession(let session):
            Task {
                try? await apiClient.detachPaymentMethod(
                    paymentMethod.stripeId,
                    fromCheckoutSession: session.id
                )
            }
        case .customer(let customer):
            guard let customer,
                  let ephemeralKey = ephemeralKeySecret(basedOn: elementsSession) else {
                logMissingEphemeralKey()
                return
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
        }
    }

    @MainActor
    func setAsDefaultPaymentMethod(
        _ paymentMethodID: String,
        elementsSession: STPElementsSession,
        apiClient: STPAPIClient
    ) async throws -> STPCustomer {
        guard let ephemeralKey = ephemeralKeySecret(basedOn: elementsSession) else {
            logMissingEphemeralKey()
            throw PaymentSheetError.unknown(
                debugDescription: "Failed to read ephemeral key while setting a payment method as default."
            )
        }
        guard let customerID else {
            throw PaymentSheetError.unknown(
                debugDescription: "Failed to read customerId while setting a payment method as default."
            )
        }
        return try await apiClient.setAsDefaultPaymentMethod(
            paymentMethodID,
            for: customerID,
            using: ephemeralKey
        )
    }

    private func logMissingEphemeralKey() {
        let errorAnalytic = ErrorAnalytic(
            event: .unexpectedPaymentSheetError,
            error: Error.missingEphemeralKey,
            additionalNonPIIParams: ["customer_access_provider": analyticValue ?? "unknown"]
        )
        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
    }
}
