//
//  FlowControllerSelectionSnapshot.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/23/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Captures the selection when payment options open so it can be restored if the customer cancels.
internal struct FlowControllerSelectionSnapshot {
    struct Selection {
        var paymentOption: PaymentOption?
        let formConfirmParams: IntentConfirmParams?
    }

    private let selection: Selection
    private let persistedSelection: CustomerPaymentOption.PersistedSelectionSnapshot

    init(viewController: FlowControllerViewControllerProtocol, customerID: String?) {
        self.selection = .init(
            paymentOption: viewController.selectedPaymentOption,
            formConfirmParams: viewController.formConfirmParamsForCancellationRestoration
        )
        self.persistedSelection = .init(
            customerID: customerID,
            availableSavedPaymentMethods: viewController.savedPaymentMethods
        )
    }

    /// Returns the captured selection when the current view controller must be rebuilt to restore it.
    /// Returns nil when the current controller can be reused to preserve form state not represented
    /// by PaymentOption.
    func selectionForRebuilding(
        using viewController: FlowControllerViewControllerProtocol
    ) -> Selection? {
        // Selecting a saved method updates its persisted default immediately, so cancellation
        // must roll that back even when the current view controller can be reused.
        persistedSelection.revertPersistedSelection(using: viewController.savedPaymentMethods)

        var selectionToRestore = selection
        // Form-backed `.saved` options are not expected in savedPaymentMethods. For ordinary
        // saved options, however, a missing payment method means it was deleted while the sheet
        // was open and should not be restored.
        if case let .saved(paymentMethod, confirmParams) = selectionToRestore.paymentOption,
           confirmParams?.instantDebitsLinkedBank == nil,
           !viewController.savedPaymentMethods.contains(where: { $0.stripeId == paymentMethod.stripeId }) {
            // Deletion is not canceled. Keep the fallback selected by the saved-method manager.
            selectionToRestore.paymentOption = viewController.selectedPaymentOption
        }

        switch (selectionToRestore.paymentOption, viewController.selectedPaymentOption) {
        case (nil, nil):
            return nil
        case (.link(.wallet)?, .link(.wallet)?):
            return nil
        default:
            return selectionToRestore
        }
    }
}
