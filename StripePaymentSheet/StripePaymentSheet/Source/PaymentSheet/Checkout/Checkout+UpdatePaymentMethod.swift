//
//  Checkout+UpdatePaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/15/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension Checkout {
    /// Updates a saved payment method's billing details and/or card expiry, commits the refreshed
    /// session, then syncs the updated billing address so tax stays accurate.
    /// - Returns: The updated payment method, or nil if the response didn't include it.
    func updatePaymentMethod(
        _ paymentMethodId: String,
        billingDetails: PaymentMethodBillingDetails?,
        expiryDetails: PaymentMethodExpiryDetails?
    ) async throws -> STPPaymentMethod? {
        try await performUpdate(
            .updatePaymentMethod(id: paymentMethodId, billing: billingDetails, expiry: expiryDetails),
            canUpdateWhileSheetPresented: true
        )
        guard let updatedPaymentMethod = session.customer?.paymentMethods.first(where: { $0.stripeId == paymentMethodId }) else {
            return nil
        }
        // Sync the (possibly edited) billing address after the update; no-ops when unchanged.
        try await syncBillingAddress(from: updatedPaymentMethod.billingDetails)
        return updatedPaymentMethod
    }
}
