//
//  CheckoutSessionBillingAddressUpdater.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/17/26.
//

/// Narrow Checkout interface for MPE billing tax updates.
///
/// This keeps MPE plumbing from depending on the full `Checkout` object or reading
/// `checkout.session` directly. Callers must use these sanctioned update methods to sync
/// billing tax changes.
@MainActor
protocol CheckoutSessionBillingAddressUpdater: AnyObject {
    func updateBillingTaxRegionIfNecessaryForPaymentSheet(
        address: CheckoutController.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> CheckoutController.Session
}

extension CheckoutController: CheckoutSessionBillingAddressUpdater {
    func updateBillingTaxRegionIfNecessaryForPaymentSheet(
        address: Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Session {
        try await updateBillingTaxRegionIfNecessary(
            address: address,
            canUpdateWhileSheetPresented: canUpdateWhileSheetPresented,
            source: .paymentElement
        )
        return session
    }
}
