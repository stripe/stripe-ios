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
    enum ViewControllerRestoration {
        /// The current view controller already represents the captured selection. Reuse it to
        /// preserve form state that is not represented by PaymentOption.
        case reuseCurrentViewController
        /// Rebuild the view controller to discard canceled changes and restore this payment option.
        case rebuildViewController(restoring: PaymentOption?)
    }

    private let paymentOption: PaymentOption?
    private let persistedSelection: CustomerPaymentOption.PersistedSelectionSnapshot

    init(viewController: FlowControllerViewControllerProtocol, customerID: String?) {
        self.paymentOption = viewController.selectedPaymentOption
        self.persistedSelection = .init(
            customerID: customerID,
            availableSavedPaymentMethods: viewController.savedPaymentMethods
        )
    }

    func viewControllerRestoration(
        using viewController: FlowControllerViewControllerProtocol
    ) -> ViewControllerRestoration {
        persistedSelection.revertPersistedSelection(using: viewController.savedPaymentMethods)

        var paymentOptionToRestore = paymentOption
        // Form-backed `.saved` options are not expected in savedPaymentMethods. For ordinary
        // saved options, however, a missing payment method means it was deleted while the sheet
        // was open and should not be restored.
        if case let .saved(paymentMethod, confirmParams) = paymentOptionToRestore,
           confirmParams?.isFormBackedSavedPaymentMethod != true,
           !viewController.savedPaymentMethods.contains(where: { $0.stripeId == paymentMethod.stripeId }) {
            // Deletion is not canceled. Keep the fallback selected by the saved-method manager.
            paymentOptionToRestore = viewController.selectedPaymentOption
        }

        switch (paymentOptionToRestore, viewController.selectedPaymentOption) {
        case (nil, nil):
            return .reuseCurrentViewController
        case (.link(.wallet)?, .link(.wallet)?):
            return .reuseCurrentViewController
        default:
            return .rebuildViewController(restoring: paymentOptionToRestore)
        }
    }
}
