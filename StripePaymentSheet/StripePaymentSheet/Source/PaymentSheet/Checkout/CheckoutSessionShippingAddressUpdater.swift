//
//  CheckoutSessionShippingAddressUpdater.swift
//  StripePaymentSheet
//

/// Narrow Checkout interface for MPE shipping tax updates.
///
/// This keeps MPE plumbing from depending on the full `Checkout` object or reading
/// `checkout.session` directly. Callers must use this sanctioned update method to sync
/// shipping tax changes.
@MainActor
protocol CheckoutSessionShippingAddressUpdater: AnyObject {
    func updateShippingTaxRegionIfNecessaryForPaymentSheet(
        address: Checkout.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Checkout.Session
}

extension Checkout: CheckoutSessionShippingAddressUpdater {
    func updateShippingTaxRegionIfNecessaryForPaymentSheet(
        address: Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Session {
        try await updateShippingTaxRegionIfNecessary(
            address: address,
            canUpdateWhileSheetPresented: canUpdateWhileSheetPresented
        )
        return session
    }
}
