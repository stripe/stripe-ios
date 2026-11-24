//
//  CheckoutSessionSavedPaymentMethodUpdater.swift
//  StripePaymentSheet
//
//  Created by George Birch on 11/18/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// Narrow Checkout interface for removing and editing saved payment methods from Payment Element.
///
/// Changes go through the Checkout Session update queue, so they reach the server in order with other
/// session updates such as billing tax syncs. The returned session is committed so that the controller's
/// session reflects the change. Otherwise, the next rebuild of Payment Element would restore a removed
/// payment method or revert an edit.
@MainActor
protocol CheckoutSessionSavedPaymentMethodUpdater: AnyObject {

    func detachSavedPaymentMethod(_ paymentMethodID: String) async throws

    /// - Returns: The committed session, which contains the updated payment method.
    func updateSavedPaymentMethod(
        _ paymentMethodID: String,
        billingDetails: CheckoutElementsController.PaymentMethodBillingDetails?,
        expiryDetails: CheckoutElementsController.PaymentMethodExpiryDetails?
    ) async throws -> CheckoutElementsController.Session
}

/// The Checkout interfaces that Payment Element's screens use to sync billing tax and to remove or edit saved payment methods.
typealias CheckoutSessionPaymentElementUpdater = CheckoutSessionBillingAddressUpdater & CheckoutSessionSavedPaymentMethodUpdater

// These run while Payment Element's UI is usually presented, so unlike merchant updates they don't
// require the sheet to be dismissed. They also don't call `updateForSessionChange()`: the presented UI
// already shows the change, and rebuilding Payment Element underneath it would disconnect that UI from
// Payment Element. Later rebuilds read the committed session.
extension CheckoutElementsController: CheckoutSessionSavedPaymentMethodUpdater {

    func detachSavedPaymentMethod(_ paymentMethodID: String) async throws {
        try await enqueueSessionUpdate {
            let response = try await self.apiClient.detachPaymentMethod(
                paymentMethodID,
                fromCheckoutSession: Self.extractSessionId(from: self.clientSecret),
                clientSecret: self.clientSecret
            )
            self.commitSession(response)
        }
    }

    func updateSavedPaymentMethod(
        _ paymentMethodID: String,
        billingDetails: PaymentMethodBillingDetails?,
        expiryDetails: PaymentMethodExpiryDetails?
    ) async throws -> Session {
        try await enqueueSessionUpdate {
            let response = try await self.apiClient.updatePaymentMethod(
                paymentMethodID,
                inCheckoutSession: Self.extractSessionId(from: self.clientSecret),
                clientSecret: self.clientSecret,
                billingDetails: billingDetails,
                expiryDetails: expiryDetails
            )
            self.commitSession(response)
            return self.session
        }
    }
}
