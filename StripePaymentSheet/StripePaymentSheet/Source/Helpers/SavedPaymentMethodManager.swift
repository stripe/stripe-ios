//
//  SavedPaymentMethodManager.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/2/24.
//

import Foundation
@_spi(STP) import StripePayments

/// Provides shared implementations of common operations for managing saved payment methods in PaymentSheet
final class SavedPaymentMethodManager {

    let configuration: PaymentSheet.Configuration

    init(configuration: PaymentSheet.Configuration) {
        self.configuration = configuration
    }

    func update(paymentMethod: STPPaymentMethod,
                with updateParams: STPPaymentMethodUpdateParams,
                using ephemeralKey: String) async throws -> STPPaymentMethod {
        return try await configuration.apiClient.updatePaymentMethod(with: paymentMethod.stripeId,
                                                                     paymentMethodUpdateParams: updateParams,
                                                                     ephemeralKeySecret: ephemeralKey)
    }

    func detach(paymentMethod: STPPaymentMethod, using ephemeralKey: String) {
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
