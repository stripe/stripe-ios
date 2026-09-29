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

    let customerProvider: CustomerProvider
    let apiClient: STPAPIClient
    let elementsSession: STPElementsSession

    init(customerProvider: CustomerProvider, elementsSession: STPElementsSession, apiClient: STPAPIClient) {
        self.customerProvider = customerProvider
        self.apiClient = apiClient
        self.elementsSession = elementsSession
    }

    func update(paymentMethod: STPPaymentMethod,
                with updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        do {
            return try await customerProvider.update(
                paymentMethod: paymentMethod,
                with: updateParams,
                elementsSession: elementsSession,
                apiClient: apiClient
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
        let didStartDetaching = customerProvider.detach(
            paymentMethod: paymentMethod,
            elementsSession: elementsSession,
            apiClient: apiClient
        )
        if !didStartDetaching {
            logMissingEphemeralKey()
        }
    }

    func setAsDefaultPaymentMethod(defaultPaymentMethodId: String) async throws -> STPCustomer {
        do {
            return try await customerProvider.setAsDefaultPaymentMethod(
                defaultPaymentMethodId,
                elementsSession: elementsSession,
                apiClient: apiClient
            )
        } catch CustomerProvider.Error.missingEphemeralKey {
            logMissingEphemeralKey()
            throw PaymentSheetError.unknown(
                debugDescription: "Failed to read ephemeral key while setting a payment method as default."
            )
        } catch CustomerProvider.Error.missingCustomerID {
            throw PaymentSheetError.unknown(
                debugDescription: "Failed to read customerId while setting a payment method as default."
            )
        }
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
