//
//  PollingAuthenticationHandler.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore

/// Handles authentication actions that require polling for status updates.
///
/// This includes:
/// - BLIK (Poland bank authorization)
/// - UPI (India bank app authorization)
/// - PayNow (Singapore QR code payment)
/// - PromptPay (Thailand QR code payment)
/// - Microdeposits verification (US bank account)
final class PollingAuthenticationHandler: AuthenticationHandler {

    private let missingReturnURLErrorMessage = "The payment method requires a return URL and one was not provided. Your integration should provide one in your `STPPaymentIntentConfirmParams`/`STPSetupIntentConfirmParams` object if you call `STPPaymentHandler.confirm...` or when you call  `STPPaymentHandler.handleNextAction`."

    func canHandle(actionType: STPIntentActionType) -> Bool {
        switch actionType {
        case .BLIKAuthorize,
             .upiAwaitNotification,
             .payNowDisplayQrCode,
             .promptpayDisplayQrCode,
             .verifyWithMicrodeposits:
            return true
        default:
            return false
        }
    }

    func handle(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        switch action.type {
        case .BLIKAuthorize:
            handleBLIKAuthorize(action: action, currentAction: currentAction, paymentHandler: paymentHandler)

        case .upiAwaitNotification:
            handleUPIAwaitNotification(action: action, currentAction: currentAction, paymentHandler: paymentHandler)

        case .payNowDisplayQrCode:
            handlePayNowDisplayQrCode(action: action, currentAction: currentAction, paymentHandler: paymentHandler)

        case .promptpayDisplayQrCode:
            handlePromptPayDisplayQrCode(action: action, currentAction: currentAction, paymentHandler: paymentHandler)

        case .verifyWithMicrodeposits:
            // The customer must authorize after the microdeposits appear in their bank account
            // which may take 1-2 business days
            currentAction.complete(with: .succeeded, error: nil)

        default:
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unsupportedAuthenticationErrorCode,
                    loggingSafeErrorMessage: "PollingAuthenticationHandler cannot handle action type: \(action.type)"
                )
            )
        }
    }

    // MARK: - Private Handlers

    private func handleBLIKAuthorize(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        // The customer must authorize the transaction in their banking app within 1 minute
        if let presentingVC = currentAction.authenticationContext as? PaymentSheetAuthenticationContext {
            guard let paymentIntentAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams else {
                currentAction.complete(
                    with: .failed,
                    error: createError(
                        for: .unexpectedErrorCode,
                        loggingSafeErrorMessage: "Handling BLIKAuthorize next action with SetupIntent is not supported"
                    )
                )
                return
            }
            // If we are using PaymentSheet, PollingViewController will poll Stripe to determine success
            presentingVC.presentPollingVCForAction(action: paymentIntentAction, type: .blik, safariViewController: nil)
        } else {
            // The merchant integration should spin and poll their backend or Stripe to determine success
            currentAction.complete(with: .succeeded, error: nil)
        }
    }

    private func handleUPIAwaitNotification(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        // The customer must authorize the transaction in their banking app within 5 minutes
        if let presentingVC = currentAction.authenticationContext as? PaymentSheetAuthenticationContext {
            guard let paymentIntentAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams else {
                currentAction.complete(
                    with: .failed,
                    error: createError(
                        for: .unexpectedErrorCode,
                        loggingSafeErrorMessage: "Handling upiAwaitNotification next action with SetupIntent is not supported"
                    )
                )
                return
            }
            // If we are using PaymentSheet, PollingViewController will poll Stripe to determine success
            presentingVC.presentPollingVCForAction(action: paymentIntentAction, type: .UPI, safariViewController: nil)
        } else {
            // The merchant integration should spin and poll their backend or Stripe to determine success
            currentAction.complete(with: .succeeded, error: nil)
        }
    }

    private func handlePayNowDisplayQrCode(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let returnURL = URL(string: currentAction.returnURLString ?? "") else {
            assertionFailure(missingReturnURLErrorMessage)
            currentAction.complete(with: .failed, error: createError(for: .missingReturnURL))
            return
        }

        guard let hostedInstructionsURL = action.payNowDisplayQrCode?.hostedInstructionsURL else {
            completeWithMissingDetails(currentAction: currentAction, actionType: action.type)
            return
        }

        guard let presentingVC = currentAction.authenticationContext as? PaymentSheetAuthenticationContext else {
            assertionFailure("PayNow is not supported outside of PaymentSheet.")
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unsupportedAuthenticationErrorCode,
                    loggingSafeErrorMessage: "PayNow is not supported outside of PaymentSheet."
                )
            )
            return
        }

        guard let paymentIntentAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams else {
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "Handling payNowDisplayQrCode next action with SetupIntent is not supported"
                )
            )
            return
        }

        paymentHandler._handleRedirect(
            to: hostedInstructionsURL,
            fallbackURL: hostedInstructionsURL,
            return: returnURL,
            useWebAuthSession: false
        ) { safariViewController in
            // Present the polling view controller behind the web view so we can start polling right away
            presentingVC.presentPollingVCForAction(action: paymentIntentAction, type: .paynow, safariViewController: safariViewController)
        }
    }

    private func handlePromptPayDisplayQrCode(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let returnURL = URL(string: currentAction.returnURLString ?? "") else {
            assertionFailure(missingReturnURLErrorMessage)
            currentAction.complete(with: .failed, error: createError(for: .missingReturnURL))
            return
        }

        guard let hostedInstructionsURL = action.promptPayDisplayQrCode?.hostedInstructionsURL else {
            completeWithMissingDetails(currentAction: currentAction, actionType: action.type)
            return
        }

        guard let presentingVC = currentAction.authenticationContext as? PaymentSheetAuthenticationContext else {
            assertionFailure("PromptPay is not supported outside of PaymentSheet.")
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unsupportedAuthenticationErrorCode,
                    loggingSafeErrorMessage: "PromptPay is not supported outside of PaymentSheet."
                )
            )
            return
        }

        guard let paymentIntentAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams else {
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "Handling promptpayDisplayQrCode next action with SetupIntent is not supported"
                )
            )
            return
        }

        paymentHandler._handleRedirect(
            to: hostedInstructionsURL,
            fallbackURL: hostedInstructionsURL,
            return: returnURL,
            useWebAuthSession: false
        ) { safariViewController in
            // Present the polling view controller behind the web view so we can start polling right away
            presentingVC.presentPollingVCForAction(action: paymentIntentAction, type: .promptPay, safariViewController: safariViewController)
        }
    }

    // MARK: - Helpers

    private func completeWithMissingDetails(
        currentAction: STPPaymentHandlerActionParams,
        actionType: STPIntentActionType
    ) {
        currentAction.complete(
            with: .failed,
            error: createError(
                for: .unexpectedErrorCode,
                loggingSafeErrorMessage: "Authentication action \(actionType) is missing expected details."
            )
        )
    }
}
