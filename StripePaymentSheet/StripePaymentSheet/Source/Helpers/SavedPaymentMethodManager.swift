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

    private lazy var ephemeralKey: String? = {
        guard let ephemeralKey = configuration.customer?.ephemeralKeySecretBasedOn(elementsSession: elementsSession) else {
            stpAssert(true, "Failed to read ephemeral key.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.missingEphemeralKey,
                                              additionalNonPIIParams: ["customer_access_provider": configuration.customer?.customerAccessProvider.analyticValue ?? "unknown"])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            return nil
        }
        return ephemeralKey
    }()

    init(configuration: PaymentElementConfiguration, elementsSession: STPElementsSession) {
        self.configuration = configuration
        self.elementsSession = elementsSession
    }

    func update(paymentMethod: STPPaymentMethod,
                with updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        guard let ephemeralKey else {
            throw PaymentSheetError.unknown(debugDescription: "Failed to read ephemeral key while updating a payment method.")
        }

        return try await configuration.apiClient.updatePaymentMethod(with: paymentMethod.stripeId,
                                                                     paymentMethodUpdateParams: updateParams,
                                                                     ephemeralKeySecret: ephemeralKey)
    }

    func detach(paymentMethod: STPPaymentMethod) {
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
