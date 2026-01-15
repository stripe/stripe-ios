//
//  STPPaymentHandler+IntentRetrieval.swift
//  StripePayments
//
//  Created for STPPaymentHandler refactoring.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

// MARK: - Intent Retrieval and Status Checking

extension STPPaymentHandler {

    /// Retrieves the current intent and checks its status, with retry and polling support.
    ///
    /// This method handles:
    /// - Alipay's Marlin ping requirement
    /// - Intent retrieval with error retry
    /// - Processing status polling
    /// - RequiresAction status handling
    ///
    /// - Parameters:
    ///   - currentAction: Action parameters to process, defaults to self.currentAction
    ///   - pollingBudget: Existing polling budget, or nil for first attempt
    func _retrieveAndCheckIntentForCurrentAction(
        currentAction: STPPaymentHandlerActionParams? = nil,
        pollingBudget: PollingBudget? = nil
    ) {
        guard let currentAction = currentAction ?? self.currentAction else {
            stpAssertionFailure("Calling _retrieveAndCheckIntentForCurrentAction without a currentAction")
            let errorAnalytic = ErrorAnalytic(
                event: .unexpectedPaymentHandlerError,
                error: InternalError.invalidState,
                additionalNonPIIParams: ["error_message": "Calling _retrieveAndCheckIntentForCurrentAction without a currentAction"]
            )
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }

        if let paymentAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams {
            _retrieveAndCheckPaymentIntent(action: paymentAction, pollingBudget: pollingBudget)
        } else if let setupAction = currentAction as? STPPaymentHandlerSetupIntentActionParams {
            _retrieveAndCheckSetupIntent(action: setupAction, pollingBudget: pollingBudget)
        } else {
            stpAssert(false, "currentAction is an unknown type or nil intent.")
            currentAction.complete(
                with: .failed,
                error: _error(for: .unexpectedErrorCode, loggingSafeErrorMessage: "currentAction is an unknown type or nil intent.")
            )
        }
    }

    // MARK: - PaymentIntent Retrieval

    private func _retrieveAndCheckPaymentIntent(
        action: STPPaymentHandlerPaymentIntentActionParams,
        pollingBudget: PollingBudget?
    ) {
        // Alipay requires us to hit an endpoint before retrieving the PI, to ensure the status is up to date.
        _pingMarlinIfNecessary(action: action) { [weak self] in
            self?._doRetrieveAndCheckPaymentIntent(action: action, pollingBudget: pollingBudget)
        }
    }

    private func _doRetrieveAndCheckPaymentIntent(
        action: STPPaymentHandlerPaymentIntentActionParams,
        pollingBudget: PollingBudget?
    ) {
        let startDate = Date()

        retrieveOrRefreshPaymentIntent(
            currentAction: action,
            timeout: pollingBudget?.networkTimeout
        ) { [weak self] paymentIntent, error in
            guard let self else { return }

            guard let paymentIntent, error == nil else {
                self._handleRetrievalError(
                    action: action,
                    error: error,
                    pollingBudget: pollingBudget,
                    intentType: "PaymentIntent"
                )
                return
            }

            action.paymentIntent = paymentIntent

            // Check if still processing and needs polling
            if self._shouldPollForProcessing(intent: paymentIntent, pollingBudget: pollingBudget) {
                let processingPollingBudget = pollingBudget ?? PollingBudget(startDate: startDate, duration: 30)
                processingPollingBudget.pollAfter {
                    self._retrieveAndCheckIntentForCurrentAction(pollingBudget: processingPollingBudget)
                }
                return
            }

            // Handle the status
            let requiresAction = self._handlePaymentIntentStatus(forAction: action)

            if requiresAction {
                self._handleRequiresActionForPaymentIntent(
                    action: action,
                    paymentIntent: paymentIntent,
                    pollingBudget: pollingBudget,
                    startDate: startDate
                )
            }
        }
    }

    private func _handleRequiresActionForPaymentIntent(
        action: STPPaymentHandlerPaymentIntentActionParams,
        paymentIntent: STPPaymentIntent,
        pollingBudget: PollingBudget?,
        startDate: Date
    ) {
        // Determine payment method type
        let paymentMethodType: STPPaymentMethodType? = {
            if let paymentMethod = paymentIntent.paymentMethod {
                return paymentMethod.type
            }
            if paymentIntent.isRedacted && paymentIntent.nextAction?.type == .useStripeSDK {
                // For now, we'll assume redacted PIs are card
                return .card
            }
            return nil
        }()

        guard let paymentMethodType else {
            action.complete(
                with: .failed,
                error: _error(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "PaymentIntent requires action but missing payment method type data."
                )
            )
            return
        }

        _handleRequiresActionCommon(
            action: action,
            paymentMethodType: paymentMethodType,
            nextAction: paymentIntent.nextAction,
            pollingBudget: pollingBudget,
            startDate: startDate,
            shouldSkipCancel: paymentMethodType == .paynow || paymentMethodType == .promptPay
        )
    }

    // MARK: - SetupIntent Retrieval

    private func _retrieveAndCheckSetupIntent(
        action: STPPaymentHandlerSetupIntentActionParams,
        pollingBudget: PollingBudget?
    ) {
        let startDate = Date()

        retrieveOrRefreshSetupIntent(
            currentAction: action,
            timeout: pollingBudget?.networkTimeout
        ) { [weak self] setupIntent, error in
            guard let self else { return }

            guard let setupIntent, error == nil else {
                self._handleRetrievalError(
                    action: action,
                    error: error,
                    pollingBudget: pollingBudget,
                    intentType: "SetupIntent"
                )
                return
            }

            action.setupIntent = setupIntent

            // Check if still processing and needs polling
            if self._shouldPollForProcessing(intent: setupIntent, pollingBudget: pollingBudget) {
                let processingPollingBudget = pollingBudget ?? PollingBudget(startDate: startDate, duration: 30)
                processingPollingBudget.pollAfter {
                    self._retrieveAndCheckIntentForCurrentAction(pollingBudget: processingPollingBudget)
                }
                return
            }

            // Handle the status
            let requiresAction = self._handleSetupIntentStatus(forAction: action)

            if requiresAction {
                self._handleRequiresActionForSetupIntent(
                    action: action,
                    setupIntent: setupIntent,
                    pollingBudget: pollingBudget,
                    startDate: startDate
                )
            }
        }
    }

    private func _handleRequiresActionForSetupIntent(
        action: STPPaymentHandlerSetupIntentActionParams,
        setupIntent: STPSetupIntent,
        pollingBudget: PollingBudget?,
        startDate: Date
    ) {
        guard let paymentMethod = setupIntent.paymentMethod else {
            action.complete(
                with: .failed,
                error: _error(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "SetupIntent requires action but missing PaymentMethod."
                )
            )
            return
        }

        _handleRequiresActionCommon(
            action: action,
            paymentMethodType: paymentMethod.type,
            nextAction: setupIntent.nextAction,
            pollingBudget: pollingBudget,
            startDate: startDate,
            shouldSkipCancel: false
        )
    }

    // MARK: - Common Helpers

    /// Pings Alipay's Marlin endpoint if necessary before retrieving the intent.
    private func _pingMarlinIfNecessary(
        action: STPPaymentHandlerPaymentIntentActionParams,
        completion: @escaping STPVoidBlock
    ) {
        guard let paymentMethod = action.paymentIntent.paymentMethod,
              paymentMethod.type == .alipay,
              let alipayHandleRedirect = action.nextAction()?.alipayHandleRedirect,
              let alipayReturnURL = alipayHandleRedirect.marlinReturnURL
        else {
            completion()
            return
        }

        // Make a request to the return URL
        let request = URLRequest(url: alipayReturnURL)
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
            completion()
        }
        task.resume()
    }

    /// Handles retrieval errors with retry logic.
    private func _handleRetrievalError(
        action: STPPaymentHandlerActionParams,
        error: Error?,
        pollingBudget: PollingBudget?,
        intentType: String
    ) {
        // Retry if polling budget allows. For the first call (no polling budget), create a minimal
        // budget to allow one retry. This handles transient network errors.
        let effectivePollingBudget = pollingBudget ?? PollingBudget(startDate: Date(), duration: 1)

        if effectivePollingBudget.canPoll {
            effectivePollingBudget.pollAfter { [weak self] in
                self?._retrieveAndCheckIntentForCurrentAction(pollingBudget: pollingBudget)
            }
        } else {
            let finalError = error ?? _error(
                for: .unexpectedErrorCode,
                loggingSafeErrorMessage: "Missing \(intentType)."
            )
            action.complete(with: .failed, error: finalError as NSError)
        }
    }

    /// Checks if we should continue polling for a processing status.
    private func _shouldPollForProcessing(intent: any StripeIntent, pollingBudget: PollingBudget?) -> Bool {
        guard let paymentMethodType = intent.paymentMethod?.type,
              !STPPaymentHandler._isProcessingIntentSuccess(for: paymentMethodType),
              intent.unifiedStatus == .processing,
              pollingBudget?.canPoll ?? true
        else {
            return false
        }
        return true
    }

    /// Common handling for requires_action status.
    private func _handleRequiresActionCommon(
        action: STPPaymentHandlerActionParams,
        paymentMethodType: STPPaymentMethodType,
        nextAction: STPIntentAction?,
        pollingBudget: PollingBudget?,
        startDate: Date,
        shouldSkipCancel: Bool
    ) {
        // If it's a valid terminal next action (voucher display, etc.), consider it success
        if isNextActionSuccessState(nextAction: nextAction) {
            action.complete(with: .succeeded, error: nil)
            return
        }

        // Check if we should retry polling
        let shouldRetryForCard = paymentMethodType == .card && nextAction?.type == .useStripeSDK
        let shouldPoll = paymentMethodType != .card || shouldRetryForCard

        if shouldPoll,
           let budget = pollingBudget ?? PollingBudget(startDate: startDate, paymentMethodType: paymentMethodType),
           budget.canPoll
        {
            budget.pollAfter { [weak self] in
                self?._retrieveAndCheckIntentForCurrentAction(pollingBudget: budget)
            }
            return
        }

        // If we shouldn't skip cancel, mark the challenge as canceled
        if !shouldSkipCancel {
            _markChallengeCanceled(currentAction: action) { [weak action] _, _ in
                // We don't forward cancelation errors
                action?.complete(with: .canceled, error: nil)
            }
        }
    }
}
