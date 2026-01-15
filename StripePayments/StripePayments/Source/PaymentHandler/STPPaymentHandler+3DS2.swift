//
//  STPPaymentHandler+3DS2.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

#if canImport(Stripe3DS2)
import Stripe3DS2
#endif

// MARK: - 3DS2 Challenge Status Receiver

extension STPPaymentHandler {

    /// :nodoc:
    @objc(transaction:didCompleteChallengeWithCompletionEvent:)
    dynamic func transaction(
        _ transaction: STDSTransaction,
        didCompleteChallengeWith completionEvent: STDSCompletionEvent
    ) {
        guard let currentAction else {
            stpAssertionFailure("Calling didCompleteChallengeWith without currentAction.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling didCompleteChallengeWith without currentAction."])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }
        let transactionStatus = completionEvent.transactionStatus
        analyticsClient.log3DS2ChallengeFlowCompleted(
            intentID: currentAction.intentStripeID,
            uiType: transaction.presentedChallengeUIType
        )
        if transactionStatus == "Y" {
            _markChallengeCompleted(withCompletion: { _, _ in
                if let currentAction = self.currentAction as? STPPaymentHandlerPaymentIntentActionParams {
                    let requiresAction = self._handlePaymentIntentStatus(forAction: currentAction)
                    if requiresAction {
                        stpAssertionFailure("3DS2 challenge completed, but the PaymentIntent is still requiresAction")
                        currentAction.complete(
                            with: .failed,
                            error: self._error(for: .unexpectedErrorCode, loggingSafeErrorMessage: "3DS2 challenge completed, but the PaymentIntent is still requiresAction")
                        )
                    }
                } else if let currentAction = self.currentAction as? STPPaymentHandlerSetupIntentActionParams {
                    let requiresAction = self._handleSetupIntentStatus(forAction: currentAction)
                    if requiresAction {
                        stpAssertionFailure("3DS2 challenge completed, but the SetupIntent is still requiresAction")
                        currentAction.complete(
                            with: STPPaymentHandlerActionStatus.failed,
                            error: self._error(for: .unexpectedErrorCode, loggingSafeErrorMessage: "3DS2 challenge completed, but the SetupIntent is still requiresAction")
                        )
                    }
                }
            })
        } else {
            _markChallengeCompleted(withCompletion: { _, _ in
                currentAction.complete(
                    with: STPPaymentHandlerActionStatus.failed,
                    error: self._error(
                        for: .notAuthenticatedErrorCode,
                        loggingSafeErrorMessage: "Failed with transaction_status: \(transactionStatus)"
                    )
                )
            })
        }
    }

    /// :nodoc:
    @objc(transactionDidCancel:)
    dynamic func transactionDidCancel(_ transaction: STDSTransaction) {
        guard let currentAction else {
            stpAssertionFailure("Calling transactionDidCancel without currentAction.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling transactionDidCancel without currentAction."])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }

        analyticsClient.log3DS2ChallengeFlowUserCanceled(
            intentID: currentAction.intentStripeID,
            uiType: transaction.presentedChallengeUIType
        )
        _markChallengeCompleted(withCompletion: { _, _ in
            currentAction.complete(with: STPPaymentHandlerActionStatus.canceled, error: nil)
        })
    }

    /// :nodoc:
    @objc(transactionDidTimeOut:)
    dynamic func transactionDidTimeOut(_ transaction: STDSTransaction) {
        guard let currentAction else {
            stpAssertionFailure("Calling transactionDidTimeOut without currentAction.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling transactionDidTimeOut without currentAction."])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }

        analyticsClient.log3DS2ChallengeFlowTimedOut(
            intentID: currentAction.intentStripeID,
            uiType: transaction.presentedChallengeUIType
        )
        _markChallengeCompleted(withCompletion: { _, _ in
            currentAction.complete(
                with: STPPaymentHandlerActionStatus.failed,
                error: self._error(for: .timedOutErrorCode)
            )
        })
    }

    /// :nodoc:
    @objc(transaction:didErrorWithProtocolErrorEvent:)
    dynamic func transaction(
        _ transaction: STDSTransaction,
        didErrorWith protocolErrorEvent: STDSProtocolErrorEvent
    ) {
        guard let currentAction else {
            stpAssertionFailure("Calling didErrorWithProtocolErrorEvent without currentAction.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling didErrorWithProtocolErrorEvent without currentAction."])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }

        _markChallengeCompleted(withCompletion: { [weak self] _, _ in
            let threeDSError = protocolErrorEvent.errorMessage.nsErrorValue() as NSError
            var userInfo = threeDSError.userInfo
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

            let localizedError = NSError(
                domain: threeDSError.domain,
                code: threeDSError.code,
                userInfo: userInfo
            )
            self?.analyticsClient.log3DS2ChallengeFlowErrored(
                intentID: currentAction.intentStripeID,
                error: localizedError
            )
            currentAction.complete(with: .failed, error: localizedError)
        })
    }

    /// :nodoc:
    @objc(transaction:didErrorWithRuntimeErrorEvent:)
    dynamic func transaction(
        _ transaction: STDSTransaction,
        didErrorWith runtimeErrorEvent: STDSRuntimeErrorEvent
    ) {
        guard let currentAction else {
            stpAssertionFailure("Calling didErrorWithRuntimeErrorEvent without currentAction.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling didErrorWithRuntimeErrorEvent without currentAction."])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }

        _markChallengeCompleted(withCompletion: { [weak self] _, _ in
            let threeDSError = runtimeErrorEvent.nsErrorValue() as NSError
            var userInfo = threeDSError.userInfo
            userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

            let localizedError = NSError(
                domain: threeDSError.domain,
                code: threeDSError.code,
                userInfo: userInfo
            )

            self?.analyticsClient.log3DS2ChallengeFlowErrored(
                intentID: currentAction.intentStripeID,
                error: localizedError
            )
            currentAction.complete(with: STPPaymentHandlerActionStatus.failed, error: localizedError)
        })
    }

    /// :nodoc:
    @objc(transactionDidPresentChallengeScreen:)
    dynamic func transactionDidPresentChallengeScreen(_ transaction: STDSTransaction) {
        guard let currentAction else {
            stpAssertionFailure("Calling transactionDidPresentChallengeScreen without currentAction.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling transactionDidPresentChallengeScreen without currentAction."])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }

        analyticsClient.log3DS2ChallengeFlowPresented(
            intentID: currentAction.intentStripeID,
            uiType: transaction.presentedChallengeUIType
        )
    }

    /// :nodoc:
    @objc(dismissChallengeViewController:forTransaction:)
    dynamic func dismiss(
        _ challengeViewController: UIViewController,
        for transaction: STDSTransaction
    ) {
        guard let currentAction else {
            stpAssertionFailure("Calling dismiss(challengeViewController:) without currentAction.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling dismiss(challengeViewController:) without currentAction."])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }

        if let paymentSheet = currentAction.authenticationContext
            .authenticationPresentingViewController() as? PaymentSheetAuthenticationContext
        {
            paymentSheet.dismiss(challengeViewController, completion: nil)
        } else {
            challengeViewController.dismiss(animated: true, completion: nil)
        }
    }

    @_spi(STP) public func cancel3DS2ChallengeFlow() {
        guard let currentAction else {
            stpAssertionFailure("Calling cancel3DS2ChallengeFlow without currentAction.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling cancel3DS2ChallengeFlow without currentAction."])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }
        guard let transaction = currentAction.threeDS2Transaction else {
            stpAssertionFailure("Calling cancel3DS2ChallengeFlow without a threeDS2Transaction.")
            currentAction.complete(
                with: .failed,
                error: _error(for: .unexpectedErrorCode, loggingSafeErrorMessage: "Calling cancel3DS2ChallengeFlow without a threeDS2Transaction.")
            )
            return
        }
        transaction.cancelChallengeFlow()
    }
}
