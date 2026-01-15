//
//  STPPaymentHandler+IntentStatus.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

// MARK: - Intent Status Handling

extension STPPaymentHandler {

    // MARK: - Unified Status Handler

    /// Handles the intent status for any action that conforms to UnifiedIntentActionParams.
    /// Returns true if the status is .requiresAction, false otherwise.
    ///
    /// This unified method eliminates duplication between PaymentIntent and SetupIntent handling.
    func _handleIntentStatus<T: UnifiedIntentActionParams>(forAction action: T) -> Bool {
        let status = action.intent.unifiedStatus

        switch status {
        case .unknown:
            action.complete(
                with: .failed,
                error: _error(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "Unknown intent status"
                )
            )

        case .requiresPaymentMethod:
            _handleRequiresPaymentMethodStatus(forAction: action)

        case .requiresConfirmation:
            action.complete(with: .succeeded, error: nil)

        case .requiresAction:
            return true

        case .processing:
            if action.isProcessingSuccess {
                action.complete(with: .succeeded, error: nil)
            } else {
                action.complete(
                    with: .failed,
                    error: _error(for: .intentStatusErrorCode)
                )
            }

        case .succeeded:
            action.complete(with: .succeeded, error: nil)

        case .requiresCapture:
            // Only applicable to PaymentIntents
            action.complete(with: .succeeded, error: nil)

        case .canceled:
            action.complete(with: .canceled, error: nil)
        }
        return false
    }

    /// Handles the requiresPaymentMethod status, which involves error handling.
    private func _handleRequiresPaymentMethodStatus<T: UnifiedIntentActionParams>(forAction action: T) {
        if let lastError = action.lastError {
            if lastError.isAuthenticationFailure {
                action.complete(
                    with: .failed,
                    error: _error(for: .notAuthenticatedErrorCode)
                )
            } else if lastError.isCardError {
                action.complete(
                    with: .failed,
                    error: _error(
                        for: .paymentErrorCode,
                        apiErrorCode: lastError.code,
                        localizedDescription: lastError.message
                    )
                )
            } else {
                action.complete(
                    with: .failed,
                    error: _error(for: .paymentErrorCode, apiErrorCode: lastError.code)
                )
            }
        } else {
            action.complete(
                with: .failed,
                error: _error(for: .paymentErrorCode)
            )
        }
    }

    // MARK: - Legacy Methods (delegate to unified handler)

    /// Calls the current action's completion handler for the SetupIntent status,
    /// or returns YES if the status is ...RequiresAction.
    func _handleSetupIntentStatus(
        forAction action: STPPaymentHandlerSetupIntentActionParams
    ) -> Bool {
        return _handleIntentStatus(forAction: action)
    }

    /// Calls the current action's completion handler for the PaymentIntent status,
    /// or returns YES if the status is ...RequiresAction.
    func _handlePaymentIntentStatus(
        forAction action: STPPaymentHandlerPaymentIntentActionParams
    ) -> Bool {
        return _handleIntentStatus(forAction: action)
    }

    /// Check if the intent.nextAction is expected state after a successful on-session transaction
    /// e.g. for voucher-based payment methods like OXXO that require out-of-band payment
    func isNextActionSuccessState(nextAction: STPIntentAction?) -> Bool {
        if let nextAction = nextAction {
            switch nextAction.type {
            case .unknown,
                .redirectToURL,
                .useStripeSDK,
                .alipayHandleRedirect,
                .weChatPayRedirectToApp,
                .cashAppRedirectToApp,
                .payNowDisplayQrCode,
                .promptpayDisplayQrCode,
                .swishHandleRedirect:
                return false
            case .OXXODisplayDetails,
                .boletoDisplayDetails,
                .konbiniDisplayDetails,
                .verifyWithMicrodeposits,
                .BLIKAuthorize,
                .upiAwaitNotification,
                .multibancoDisplayDetails:
                return true
            }
        }
        return false
    }

    /// Depending on the PaymentMethod Type, after handling next action and confirming,
    /// we should either expect a success state on the PaymentIntent, or for certain asynchronous
    /// PaymentMethods like SEPA Debit, processing is considered a completed PaymentIntent flow
    /// because the funds can take up to 14 days to transfer from the customer's bank.
    class func _isProcessingIntentSuccess(for type: STPPaymentMethodType) -> Bool {
        switch type {
        // Asynchronous payment methods whose intent.status is 'processing' after handling the next action
        case .SEPADebit,
            .bacsDebit,  // Bacs Debit takes 2-3 business days
            .AUBECSDebit,
            .USBankAccount:
            return true

        // Synchronous
        case .alipay,
            .card,
            .UPI,
            .iDEAL,
            .FPX,
            .cardPresent,
            .EPS,
            .payPal,
            .przelewy24,
            .bancontact,
            .netBanking,
            .OXXO,
            .grabPay,
            .afterpayClearpay,
            .blik,
            .weChatPay,
            .boleto,
            .link,
            .klarna,
            .affirm,
            .cashApp,
            .paynow,
            .zip,
            .revolutPay,
            .mobilePay,
            .amazonPay,
            .alma,
            .sunbit,
            .billie,
            .satispay,
            .crypto,
            .konbini,
            .promptPay,
            .swish,
            .twint,
            .multibanco,
            .shopPay,
            .payPay:
            return false

        case .unknown:
            return false

        @unknown default:
            return false
        }
    }
}
