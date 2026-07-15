//
//  Checkout+BillingAddress.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/7/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension Checkout {
    /// Copies the payment method's billing details onto the checkout session (for tax recalculation).
    func syncBillingAddress(from billingDetails: STPPaymentMethodBillingDetails?) async throws {
        guard let contactAddress = Self.contactAddress(from: billingDetails) else {
            return
        }
        try await updateBillingAddress(
            name: contactAddress.name,
            phone: contactAddress.phone,
            address: contactAddress.address,
            canUpdateWhileSheetPresented: true
        )
    }

    /// `true` if syncing `billingDetails` would change the session's current billing address.
    func billingAddressDiffers(from billingDetails: STPPaymentMethodBillingDetails?) -> Bool {
        guard let contactAddress = Self.contactAddress(from: billingDetails) else {
            return false
        }
        return session.billingAddress != contactAddress
    }

    /// Builds the `ContactAddress` we'd sync, or `nil` if we don't have enough info (at least a country).
    private static func contactAddress(from billingDetails: STPPaymentMethodBillingDetails?) -> ContactAddress? {
        guard let billingDetails else {
            return nil
        }
        guard let country = billingDetails.address?.country?.nonEmpty else {
            return nil
        }
        let source = billingDetails.address
        let address = Address(
            country: country,
            line1: source?.line1?.nonEmpty,
            line2: source?.line2?.nonEmpty,
            city: source?.city?.nonEmpty,
            state: source?.state?.nonEmpty,
            postalCode: source?.postalCode?.nonEmpty
        )
        return ContactAddress(name: billingDetails.name, phone: billingDetails.phone, address: address)
    }
}

// MARK: - Intent

extension Intent {
    /// Returns the checkout + billing details to sync for `paymentOption`, or `nil` if nothing to do.
    @MainActor
    func checkoutRequiringBillingSync(
        for paymentOption: PaymentOption?
    ) -> (checkout: Checkout, billingDetails: STPPaymentMethodBillingDetails)? {
        guard case .checkout(let checkout) = self else {
            return nil
        }
        guard let billingDetails = paymentOption?.billingDetails else {
            return nil
        }
        guard checkout.billingAddressDiffers(from: billingDetails) else {
            return nil
        }
        return (checkout, billingDetails)
    }

    /// Syncs billing onto the checkout session when needed, then calls `completion`.
    ///
    /// If there's nothing to sync, calls `completion` immediately. On failure, calls `onFailure` and
    /// leaves the sheet open (does not call `completion`).
    @MainActor
    func syncCheckoutBillingIfNeeded(
        for paymentOption: PaymentOption?,
        setLoading: @escaping (_ inProgress: Bool) -> Void,
        onFailure: @escaping (Error) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let (checkout, billingDetails) = checkoutRequiringBillingSync(for: paymentOption) else {
            completion()
            return
        }

        setLoading(true)
        Task { @MainActor in
            do {
                try await checkout.syncBillingAddress(from: billingDetails)
                setLoading(false)
                completion()
            } catch {
                // Set the error before clearing loading so UI refresh paths that read `error` see it.
                onFailure(error)
                setLoading(false)
            }
        }
    }
}
