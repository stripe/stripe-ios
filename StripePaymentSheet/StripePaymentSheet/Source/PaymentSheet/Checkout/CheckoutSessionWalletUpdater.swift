//
//  CheckoutSessionWalletUpdater.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 8/21/26.
//

/// Narrow Checkout interface for wallet flows (e.g. Apple Pay) that present their own sheet and
/// must sync the billing and shipping tax region *while that sheet is up*.
///
/// These flows run from inside an already in-flight, enqueued session update (the one that
/// presented the wallet sheet in the first place), so they can't enqueue another update the
/// normal way without deadlocking on themselves. This is distinct from `CheckoutSessionBillingAddressUpdater`,
/// whose callers run from fresh, non-nested contexts (e.g. a UI tap) and are fine going through the
/// regular enqueued update path.
@MainActor
protocol CheckoutSessionWalletUpdater: AnyObject {
    var currentTaxRegion: CheckoutController.Address? { get }

    /// Updates tax region for billing and shipping addresses
    /// but does not enqueue behind the checkout's pending session updates.
    /// Pass `nil` to clear the tax address and let the server select its default country.
    ///
    /// - Warning: Only call this from a context that's already serialized behind the checkout's
    ///   pending operations. Calling the enqueuing variant there would deadlock.
    func updateTaxRegionWithoutEnqueueing(
        address: CheckoutController.Address?,
        canUpdateWhileSheetPresented: Bool,
        confirmationSource: CheckoutController.ConfirmingElement
    ) async throws -> CheckoutController.Session
}

extension CheckoutController: CheckoutSessionWalletUpdater {
    func updateTaxRegionWithoutEnqueueing(
        address: Address?,
        canUpdateWhileSheetPresented: Bool,
        confirmationSource: CheckoutController.ConfirmingElement
    ) async throws -> Session {
        let action: CheckoutControllerAnalyticsHelper.CheckoutAction = session.automaticTaxAddressSource == "shipping" ? .updateShippingAddress : .updateBillingAddress
        let source: CheckoutControllerAnalyticsHelper.InvocationSource = confirmationSource == .expressCheckoutElement
            ? .expressCheckoutElement : (action == .updateBillingAddress ? .paymentElement : .merchant)
        let startedAction = analyticsHelper.logStarted(action, session: session, additionalParams: ["invocation_source": source.rawValue])
        var didRequestTaxUpdate = false
        var failure: Error?
        defer {
            analyticsHelper.logAddressUpdateFinished(startedAction, session: session, source: source, didRequestTaxUpdate: didRequestTaxUpdate, error: failure)
        }
        do {
            try await performUnqueuedUpdate(
                .setTaxRegion(address),
                canUpdateWhileSheetPresented: canUpdateWhileSheetPresented,
                onRequest: { didRequestTaxUpdate = true }
            )
            return session
        } catch {
            failure = error
            throw error
        }
    }
}
