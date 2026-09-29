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
@MainActor
final class SavedPaymentMethodManager {

    enum Error: Swift.Error {
        case missingEphemeralKey
        case missingUpdatedPaymentMethod
    }

    let configuration: PaymentElementConfiguration
    let customerProvider: CustomerProvider
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

    init(configuration: PaymentElementConfiguration, customerProvider: CustomerProvider, elementsSession: STPElementsSession, intent: Intent) {
        self.configuration = configuration
        self.customerProvider = customerProvider
        self.elementsSession = elementsSession
        self.intent = intent
    }

    func update(paymentMethod: STPPaymentMethod,
                with updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        do {
            return try await customerProvider.update(
                paymentMethod: paymentMethod,
                with: updateParams,
                elementsSession: elementsSession,
                apiClient: configuration.apiClient
            )
        } catch CustomerProvider.Error.missingUpdatedPaymentMethod {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.missingUpdatedPaymentMethod,
                                              additionalNonPIIParams: ["payment_method_id": paymentMethod.stripeId])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            throw PaymentSheetError.unknown(
                debugDescription: "Checkout session response didn't include the updated payment method."
            )
        } catch CustomerProvider.Error.missingEphemeralKey {
            logMissingEphemeralKey()
            throw PaymentSheetError.unknown(
                debugDescription: "Failed to read ephemeral key while updating a payment method."
            )
        }
    }

    func detach(paymentMethod: STPPaymentMethod) {
        switch intent {
        case .checkout(let session):
            Task {
                try? await configuration.apiClient.detachPaymentMethod(
                    paymentMethod.stripeId,
                    fromCheckoutSession: session.id
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

    private func logMissingEphemeralKey() {
        let errorAnalytic = ErrorAnalytic(
            event: .unexpectedPaymentSheetError,
            error: Error.missingEphemeralKey,
            additionalNonPIIParams: [
                "customer_access_provider": customerProvider.analyticValue ?? "unknown",
            ]
        )
        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
    }
}
