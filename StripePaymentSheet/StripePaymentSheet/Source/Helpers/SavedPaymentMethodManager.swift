//
//  SavedPaymentMethodManager.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/2/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Provides shared implementations of common operations for managing saved payment methods in PaymentSheet
final class SavedPaymentMethodManager {

    enum Error: Swift.Error {
        case missingEphemeralKey
    }

    let configuration: PaymentElementConfiguration
    let elementsSession: STPElementsSession
    let intent: Intent

    private lazy var ephemeralKey: String? = {
        guard let ephemeralKey = configuration.customer?.ephemeralKeySecret(basedOn: elementsSession) else {
            stpAssert(true, "Failed to read ephemeral key.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.missingEphemeralKey,
                                              additionalNonPIIParams: ["customer_access_provider": configuration.customer?.customerAccessProvider.analyticValue ?? "unknown"])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            return nil
        }
        return ephemeralKey
    }()

    init(configuration: PaymentElementConfiguration, elementsSession: STPElementsSession, intent: Intent) {
        self.configuration = configuration
        self.elementsSession = elementsSession
        self.intent = intent
    }

    func update(paymentMethod: STPPaymentMethod,
                with updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        switch intent {
        case .checkout(let checkout):
            let billing = Checkout.PaymentMethodBillingDetails(updateParams.billingDetails)
            let expiry = Checkout.PaymentMethodExpiryDetails(updateParams.card)
            guard billing != nil || expiry != nil else {
                throw PaymentSheetError.unknown(debugDescription: "Payment method update requires at least billing details or expiry details.")
            }
            let updatedSession = try await configuration.apiClient.updatePaymentMethod(
                paymentMethod.stripeId,
                inCheckoutSession: checkout.stpSession.id,
                billingDetails: billing,
                expiryDetails: expiry
            )
            guard let updatedPM = updatedSession.customer?.paymentMethods.first(where: { $0.stripeId == paymentMethod.stripeId }) else {
                throw PaymentSheetError.unknown(debugDescription: "Server response missing updated payment method.")
            }
            updatedPM.updateLocalFields(from: paymentMethod)
            return updatedPM
        case .paymentIntent, .setupIntent, .deferredIntent:
            guard let ephemeralKey else {
                throw PaymentSheetError.unknown(debugDescription: "Failed to read ephemeral key while updating a payment method.")
            }
            let updatedPaymentMethod = try await configuration.apiClient.updatePaymentMethod(with: paymentMethod.stripeId,
                                                                                             paymentMethodUpdateParams: updateParams,
                                                                                             ephemeralKeySecret: ephemeralKey)
            updatedPaymentMethod.updateLocalFields(from: paymentMethod)
            return updatedPaymentMethod
        }
    }

    func detach(paymentMethod: STPPaymentMethod) {
        switch intent {
        case .checkout(let checkout):
            Task {
                try? await configuration.apiClient.detachPaymentMethod(
                    paymentMethod.stripeId,
                    fromCheckoutSession: checkout.stpSession.id
                )
            }
        case .paymentIntent, .setupIntent, .deferredIntent:
            guard let ephemeralKey else {
                return
            }

            if let customerAccessProvider = configuration.customer?.customerAccessProvider,
               case .customerSession(let customerSessionClientSecret) = customerAccessProvider,
               let customerId = configuration.customer?.id {
                if paymentMethod.type == .card {
                    configuration.apiClient.detachPaymentMethodRemoveDuplicates(
                        paymentMethod.stripeId,
                        customerId: customerId,
                        fromCustomerUsing: ephemeralKey,
                        withCustomerSessionClientSecret: customerSessionClientSecret
                    ) { (_) in
                        // no-op
                    }
                } else {
                    configuration.apiClient.detachPaymentMethod(
                        paymentMethod.stripeId,
                        fromCustomerUsing: ephemeralKey,
                        withCustomerSessionClientSecret: customerSessionClientSecret) { (_) in
                            // no-op
                        }
                }
            } else {
                configuration.apiClient.detachPaymentMethod(
                    paymentMethod.stripeId,
                    fromCustomerUsing: ephemeralKey
                ) { (_) in
                    // no-op
                }
            }
        }
    }

    func setAsDefaultPaymentMethod(defaultPaymentMethodId: String) async throws -> STPCustomer {
        guard let ephemeralKey else {
            throw PaymentSheetError.unknown(debugDescription: "Failed to read ephemeral key while setting a payment method as default.")
        }
        guard let customerId = configuration.customer?.id else {
            throw PaymentSheetError.unknown(debugDescription: "Failed to read customerId while setting a payment method as default.")
        }
        return try await configuration.apiClient.setAsDefaultPaymentMethod(defaultPaymentMethodId, for: customerId, using: ephemeralKey)
    }
}
