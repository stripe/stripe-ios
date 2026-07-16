//
//  PaymentSheetSelectionSnapshot.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

/// A snapshot of the customer's payment method selection, captured when a sheet is presented so that
/// cancelling the sheet can revert both the in-memory selection and the locally persisted default
/// back to their at-presentation values.
struct SelectionSnapshot {
    /// The in-memory selection at presentation time.
    let paymentOption: PaymentOption?
    /// The locally persisted default (`UserDefaults`) at presentation time.
    let localCustomerPaymentOption: CustomerPaymentOption?
    /// The ids of the saved payment methods displayed by the sheet at presentation time. Used to
    /// distinguish a payment method deleted during the presentation (visible then, gone at cancel)
    /// from one that still exists but is filtered out of this sheet's display (e.g. by intent
    /// payment method types or configuration).
    let savedPaymentMethodIDsAtPresentation: Set<String>

    /// Captures the current selection state for the given customer.
    static func capture(paymentOption: PaymentOption?, customerID: String?, savedPaymentMethods: [STPPaymentMethod]) -> SelectionSnapshot {
        return SelectionSnapshot(
            paymentOption: paymentOption,
            localCustomerPaymentOption: CustomerPaymentOption.localDefaultPaymentMethod(for: customerID),
            savedPaymentMethodIDsAtPresentation: Set(savedPaymentMethods.map(\.stripeId))
        )
    }

    /// Returns a copy of this snapshot with the Link selection cleared. Used when the user drops out
    /// of the native Link flow, which deliberately deselects Link — cancelling afterwards must not
    /// resurrect Link, in memory or in the persisted default.
    var clearingLinkSelection: SelectionSnapshot {
        return SelectionSnapshot(
            paymentOption: nil,
            localCustomerPaymentOption: localCustomerPaymentOption == .link ? nil : localCustomerPaymentOption,
            savedPaymentMethodIDsAtPresentation: savedPaymentMethodIDsAtPresentation
        )
    }

    /// The in-memory restoration a cancel should perform.
    enum PaymentOptionRestoration {
        /// Revert to the given payment option (nil clears the selection).
        case revert(to: PaymentOption?)
        /// The snapshotted saved payment method was deleted while the sheet was presented; keep the
        /// sheet's own post-deletion selection instead of reverting to a dead reference.
        case keepCurrentSelection
    }

    /// Resolves the snapshotted payment option against the up-to-date saved payment methods:
    /// a customer-saved selection is re-resolved to the current object (it may have been edited
    /// while the sheet was presented, e.g. a co-branded card's preferred network changed), or
    /// dropped entirely if it was deleted. Non-saved options identify a payment method type, not a
    /// saved instance, and the available types can't change while the sheet is presented.
    func paymentOptionRestoration(savedPaymentMethods: [STPPaymentMethod]) -> PaymentOptionRestoration {
        guard case .saved(let paymentMethod, let confirmParams) = paymentOption,
              confirmParams?.isFormBackedSavedPaymentMethod != true else {
            // Form-backed saved selections (Instant Debits / Link Card Brand) aren't customer-saved:
            // they never appear in `savedPaymentMethods`, so deletions can't invalidate them.
            return .revert(to: paymentOption)
        }
        guard let currentPaymentMethod = savedPaymentMethods.first(where: { $0.stripeId == paymentMethod.stripeId }) else {
            return .keepCurrentSelection
        }
        return .revert(to: .saved(paymentMethod: currentPaymentMethod, confirmParams: confirmParams))
    }

    /// Restores the locally persisted default to its at-presentation value, unless it referenced a saved
    /// payment method that no longer exists, in which case it's cleared. Only local `UserDefaults` state
    /// is touched — the server-side default is never reverted.
    func restoreLocalPersistence(customerID: String?, savedPaymentMethods: [STPPaymentMethod]) {
        var valueToRestore = localCustomerPaymentOption
        if case .stripeId(let stripeId) = localCustomerPaymentOption,
           savedPaymentMethodIDsAtPresentation.contains(stripeId),
           !savedPaymentMethods.contains(where: { $0.stripeId == stripeId }) {
            // The persisted PM was visible at presentation but is gone now — it was deleted while
            // the sheet was presented; don't restore a dead reference. (A PM that was never visible
            // isn't deleted — it's merely filtered out of this sheet — and is restored normally.)
            valueToRestore = nil
        }
        guard valueToRestore != CustomerPaymentOption.localDefaultPaymentMethod(for: customerID) else {
            return
        }
        CustomerPaymentOption.setDefaultPaymentMethod(valueToRestore, forCustomer: customerID)
    }
}
