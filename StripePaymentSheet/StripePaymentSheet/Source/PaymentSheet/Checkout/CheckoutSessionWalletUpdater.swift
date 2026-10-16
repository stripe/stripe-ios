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
    ///
    /// - Warning: Only call this from a context that's already serialized behind the checkout's
    ///   pending operations. Calling the enqueuing variant there would deadlock.
    func updateTaxRegionWithoutEnqueueing(
        address: CheckoutController.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> CheckoutController.Session
}

extension CheckoutController: CheckoutSessionWalletUpdater {
    func updateTaxRegionWithoutEnqueueing(
        address: Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Session {
        try await applySessionUpdate(.setTaxRegion(address), canUpdateWhileSheetPresented: canUpdateWhileSheetPresented)
        return session
    }
}
