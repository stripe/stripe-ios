//
//  CheckoutSessionBillingAddressUpdater.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/17/26.
//

/// Narrow Checkout interface for MPE billing address updates.
///
/// This keeps MPE plumbing from depending on the full `Checkout` object or reading
/// `checkout.session` directly. Callers must use these sanctioned update methods to sync
/// billing changes or commit session updates.
@MainActor
protocol CheckoutSessionBillingAddressUpdater: AnyObject {
    // TODO: Delete this when CheckoutSession confirmation no longer uses `PaymentSheet.confirm`.
    func commitSession(
        _ apiResponse: PaymentPagesAPIResponse?,
        applying localMutation: (@MainActor @Sendable (Checkout.Session) -> Checkout.Session)?
    ) async throws

    func updateBillingAddressForPaymentSheet(
        name: String?,
        phone: String?,
        address: Checkout.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Checkout.Session
}

extension CheckoutSessionBillingAddressUpdater {
    func commitSession(_ apiResponse: PaymentPagesAPIResponse) async throws {
        try await commitSession(apiResponse, applying: nil)
    }

    func updateBillingAddressForPaymentSheet(
        address: Checkout.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Checkout.Session {
        try await updateBillingAddressForPaymentSheet(
            name: nil,
            phone: nil,
            address: address,
            canUpdateWhileSheetPresented: canUpdateWhileSheetPresented
        )
    }
}

extension Checkout: CheckoutSessionBillingAddressUpdater {
    func updateBillingAddressForPaymentSheet(
        name: String?,
        phone: String?,
        address: Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Session {
        try await updateBillingAddress(
            name: name,
            phone: phone,
            address: address,
            canUpdateWhileSheetPresented: canUpdateWhileSheetPresented
        )
        return session
    }
}
