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
    func commitSession(_ apiResponse: PaymentPagesAPIResponse) async throws

    func updateBillingTaxRegionIfNecessaryForPaymentSheet(
        address: CheckoutController.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> CheckoutController.Session
}

/// Narrow Checkout interface for tax-region updates made while a wallet sheet is presented.
@MainActor
protocol CheckoutSessionWalletUpdater: AnyObject {
    func updateTaxRegionWithoutEnqueueing(
        address: CheckoutController.Address,
        source: String,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> CheckoutController.Session
}

extension CheckoutController: CheckoutSessionBillingAddressUpdater {
    func commitSession(_ apiResponse: PaymentPagesAPIResponse) async throws {
        try await commitSession(
            apiResponse,
            shippingAddress: .keepOldValue,
            paymentOption: .keepOldValue
        )
    }

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

extension CheckoutController: CheckoutSessionWalletUpdater {
    func updateTaxRegionWithoutEnqueueing(
        address: Address,
        source: String,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Session {
        guard session.shouldSendTaxRegion(for: source) else {
            return session
        }
        if !canUpdateWhileSheetPresented {
            try requireSheetNotPresented()
        }
        do {
            let sessionId = Self.extractSessionId(from: clientSecret)
            let response = try await apiClient.updateCheckoutSession(
                checkoutSessionId: sessionId,
                parameters: SessionUpdate.setTaxRegion(address).parameters
            )
            try await commitSession(response)
            return session
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }
}
