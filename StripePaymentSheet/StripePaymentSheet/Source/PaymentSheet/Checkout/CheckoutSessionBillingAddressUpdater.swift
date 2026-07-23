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
/// billing tax changes or commit session updates.
@MainActor
protocol CheckoutSessionBillingAddressUpdater: AnyObject {
    // TODO: Delete this when CheckoutSession confirmation no longer uses `PaymentSheet.confirm`.
    func commitSession(
        _ apiResponse: PaymentPagesAPIResponse?,
        applying localMutation: (@MainActor @Sendable (Checkout.Session) -> Checkout.Session)?
    ) async throws

    func updateBillingTaxRegionIfNecessaryForPaymentSheet(
        address: Checkout.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Checkout.Session
}

extension CheckoutSessionBillingAddressUpdater {
    func commitSession(_ apiResponse: PaymentPagesAPIResponse) async throws {
        try await commitSession(apiResponse, applying: nil)
    }
}

extension Checkout: CheckoutSessionBillingAddressUpdater {
    func updateBillingTaxRegionIfNecessaryForPaymentSheet(
        address: Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Session {
        try await updateBillingTaxRegionIfNecessary(
            address: address,
            canUpdateWhileSheetPresented: canUpdateWhileSheetPresented
        )
        return session
    }
}
