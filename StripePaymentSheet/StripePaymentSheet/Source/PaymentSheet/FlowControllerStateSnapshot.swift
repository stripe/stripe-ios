//
//  FlowControllerStateSnapshot.swift
//  StripePaymentSheet
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

extension FlowControllerViewControllerProtocol {
    var stateForSnapshot: FlowControllerStateSnapshot.Selection {
        return .init(
            paymentOption: selectedPaymentOption
        )
    }
}

internal struct FlowControllerStateSnapshot {
    enum Source {
        case viewController
        case presented(FlowControllerStateSnapshot)
        case restored(Restoration)
    }

    struct Selection {
        var paymentOption: PaymentOption?
    }

    struct Restoration {
        let selection: Selection
        let requiresViewControllerRebuild: Bool
    }

    private let selection: Selection
    private let persistedSelection: CustomerPaymentOption.PersistedSelectionSnapshot

    init(viewController: FlowControllerViewControllerProtocol, customerID: String?) {
        self.selection = viewController.stateForSnapshot
        self.persistedSelection = .init(
            customerID: customerID,
            availableSavedPaymentMethods: viewController.savedPaymentMethods
        )
    }

    func restoration(
        using viewController: FlowControllerViewControllerProtocol
    ) -> Restoration {
        persistedSelection.revertPersistedSelection(using: viewController.savedPaymentMethods)

        var restoredSelection = selection
        if case let .saved(paymentMethod, confirmParams) = restoredSelection.paymentOption,
           confirmParams?.isFormBackedSavedPaymentMethod != true,
           !viewController.savedPaymentMethods.contains(where: { $0.stripeId == paymentMethod.stripeId }) {
            // Deletion is not canceled. Keep the fallback selected by the saved-method manager.
            restoredSelection.paymentOption = viewController.selectedPaymentOption
        }

        let requiresViewControllerRebuild: Bool
        switch (restoredSelection.paymentOption, viewController.selectedPaymentOption) {
        case (nil, nil):
            // There is no canceled selection state to discard. Reusing the form also lets it
            // resolve dynamic configuration, such as shipping details, when it next appears.
            requiresViewControllerRebuild = false
        case (.link(.wallet)?, .link(.wallet)?):
            // The accepted wallet remains selected. Reusing the controller preserves the
            // accepted payment-method form cached behind the wallet header.
            requiresViewControllerRebuild = false
        default:
            requiresViewControllerRebuild = true
        }
        return .init(
            selection: restoredSelection,
            requiresViewControllerRebuild: requiresViewControllerRebuild
        )
    }
}
