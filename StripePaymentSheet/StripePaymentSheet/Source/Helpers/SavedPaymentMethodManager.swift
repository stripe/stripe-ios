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

    let configuration: PaymentSheet.Configuration
    let intent: Intent

    private var ephemeralKey: String? {
        guard let ephemeralKey = configuration.customer?.ephemeralKeySecretBasedOn(intent: intent) else {
            stpAssert(true, "Failed to read ephemeral key.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.missingEphemeralKey,
                                              additionalNonPIIParams: ["customer_access_provider": configuration.customer?.customerAccessProvider.analyticValue as Any])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            return nil
        }
        return ephemeralKey
    }

    init(configuration: PaymentSheet.Configuration, intent: Intent) {
        self.configuration = configuration
        self.intent = intent
    }

    func update(paymentMethod: STPPaymentMethod,
                with updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        guard let ephemeralKey = ephemeralKey else {
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
           case .customerSession = customerAccessProvider,
           paymentMethod.type == .card,
           let customerId = configuration.customer?.id {
            configuration.apiClient.detachPaymentMethodRemoveDuplicates(
                paymentMethod.stripeId,
                customerId: customerId,
                fromCustomerUsing: ephemeralKey
            ) { (_) in
                // no-op
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
