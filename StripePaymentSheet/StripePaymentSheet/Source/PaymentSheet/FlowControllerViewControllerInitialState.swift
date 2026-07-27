//
//  FlowControllerViewControllerInitialState.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/23/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

extension FlowControllerViewControllerProtocol {
    var formConfirmParamsForCancellationRestoration: IntentConfirmParams? {
        return selectedPaymentOption?.formConfirmParamsForCancellationRestoration
    }
}

/// The state used to initialize a FlowController view controller.
internal enum FlowControllerViewControllerInitialState {
    /// Preserve completed form input during an ordinary rebuild. Customer/server defaults may win.
    case preservingFormInput(from: PaymentOption?)
    /// Restore the accepted state after cancellation. This selection is authoritative.
    case restoringAfterCancellation(FlowControllerSelectionSnapshot.Selection)

    var paymentOption: PaymentOption? {
        switch self {
        case .preservingFormInput(let paymentOption):
            return paymentOption
        case .restoringAfterCancellation(let selection):
            return selection.paymentOption
        }
    }

    var previousCustomerInputForHorizontalController: IntentConfirmParams? {
        switch self {
        case .preservingFormInput(let paymentOption):
            return paymentOption?.newConfirmParams
        case .restoringAfterCancellation(let selection):
            return selection.formConfirmParams
        }
    }
}
