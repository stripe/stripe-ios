//
//  STPPaymentHandler+PaymentAPI.swift
//  StripePayments
//
//  Implementation of public PaymentIntent and SetupIntent APIs.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

// MARK: - Common Validation Helpers

extension STPPaymentHandler {

    /// Validates that a new action can begin (not already processing, valid client secret).
    /// Returns an error if validation fails, nil if validation passes.
    func validateCanBeginAction(
        clientSecret: String,
        isClientSecretValid: (String) -> Bool,
        methodName: String
    ) -> NSError? {
        if isProcessing {
            assertionFailure("`\(methodName)` was called while a previous call is still in progress.")
            return _error(for: .noConcurrentActionsErrorCode)
        }
        if !isClientSecretValid(clientSecret) {
            assertionFailure("`\(methodName)` was called with an invalid client secret.")
            return _error(for: .invalidClientSecret)
        }
        return nil
    }

    /// Checks if a PaymentIntent is in a success state
    /// - Parameter includeRequiresConfirmation: If true, also considers requiresConfirmation as a success state (used by handleNextAction)
    func isPaymentIntentInSuccessState(_ paymentIntent: STPPaymentIntent, includeRequiresConfirmation: Bool = false) -> Bool {
        paymentIntent.status == .succeeded
            || paymentIntent.status == .requiresCapture
            || (includeRequiresConfirmation && paymentIntent.status == .requiresConfirmation)
            || (paymentIntent.status == .processing
                && STPPaymentHandler._isProcessingIntentSuccess(for: paymentIntent.paymentMethod?.type ?? .unknown))
            || (paymentIntent.status == .requiresAction
                && isNextActionSuccessState(nextAction: paymentIntent.nextAction))
    }

    /// Checks if a SetupIntent is in a success state
    func isSetupIntentInSuccessState(_ setupIntent: STPSetupIntent) -> Bool {
        setupIntent.status == .succeeded
            || (setupIntent.status == .requiresAction
                && isNextActionSuccessState(nextAction: setupIntent.nextAction))
    }

    /// Creates a wrapped completion for PaymentIntent that resets state and validates success
    /// - Parameter includeRequiresConfirmation: If true, also considers requiresConfirmation as a success state
    func makePaymentIntentWrappedCompletion(
        includeRequiresConfirmation: Bool = false,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) -> STPPaymentHandlerActionPaymentIntentCompletionBlock {
        return { [weak self] status, paymentIntent, error in
            guard let self else { return }
            self.isProcessing = false

            if status == .succeeded, let paymentIntent {
                if error == nil && self.isPaymentIntentInSuccessState(paymentIntent, includeRequiresConfirmation: includeRequiresConfirmation) {
                    completion(.succeeded, paymentIntent, nil)
                } else {
                    self.logPaymentIntentSuccessStateMismatch(paymentIntent: paymentIntent, error: error)
                    completion(.failed, paymentIntent, error ?? self._error(for: .intentStatusErrorCode))
                }
            } else {
                completion(status, paymentIntent, error)
            }
        }
    }

    /// Creates a wrapped completion for SetupIntent that resets state and validates success
    func makeSetupIntentWrappedCompletion(
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) -> STPPaymentHandlerActionSetupIntentCompletionBlock {
        return { [weak self] status, setupIntent, error in
            guard let self else { return }
            self.isProcessing = false

            if status == .succeeded {
                if let setupIntent, error == nil, self.isSetupIntentInSuccessState(setupIntent) {
                    completion(.succeeded, setupIntent, nil)
                } else {
                    self.logSetupIntentSuccessStateMismatch(setupIntent: setupIntent, error: error)
                    completion(.failed, setupIntent, error ?? self._error(for: .intentStatusErrorCode))
                }
            } else {
                completion(status, setupIntent, error)
            }
        }
    }

    private func logPaymentIntentSuccessStateMismatch(paymentIntent: STPPaymentIntent, error: NSError?) {
        let errorMessage = "STPPaymentHandler status is succeeded, but the PI is not in a success state or there was an error."
        stpAssertionFailure(errorMessage)
        let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: [
            "error_message": errorMessage,
            "payment_intent": paymentIntent.stripeId,
            "payment_intent_status": STPPaymentIntentStatus.string(from: paymentIntent.status),
            "error_details": error?.serializeForV1Analytics() ?? [:],
        ])
        analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
    }

    private func logSetupIntentSuccessStateMismatch(setupIntent: STPSetupIntent?, error: NSError?) {
        let errorMessage = "STPPaymentHandler status is succeeded, but the SI is not in a success state or there was an error."
        stpAssertionFailure(errorMessage)
        let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: [
            "error_message": errorMessage,
            "setup_intent": setupIntent?.stripeID ?? "nil",
            "setup_intent_status": setupIntent?.status.rawValue ?? "nil",
            "error_details": error?.serializeForV1Analytics() ?? [:],
        ])
        analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
    }
}

// MARK: - PaymentIntent API Implementation

extension STPPaymentHandler {

    func _confirmPaymentIntentImpl(
        params: STPPaymentIntentConfirmParams,
        authenticationContext: STPAuthenticationContext,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        let paymentIntentID = params.stripeId
        logConfirmPaymentIntentStarted(paymentIntentID: paymentIntentID, paymentParams: params)

        let completion: STPPaymentHandlerActionPaymentIntentCompletionBlock = { [weak self] status, paymentIntent, error in
            self?.logConfirmPaymentIntentCompleted(paymentIntentID: paymentIntentID, paymentParams: params, status: status, error: error)
            completion(status, paymentIntent, error)
        }

        if let error = validateCanBeginAction(
            clientSecret: params.clientSecret,
            isClientSecretValid: STPPaymentIntentConfirmParams.isClientSecretValid,
            methodName: "STPPaymentHandler.confirmPayment"
        ) {
            completion(.failed, nil, error)
            return
        }

        isProcessing = true

        let wrappedCompletion = makePaymentIntentWrappedCompletion(completion: completion)

        let confirmCompletionBlock: STPPaymentIntentCompletionBlock = { [weak self] paymentIntent, error in
            guard let self else {
                assertionFailure("STPPaymentHandler became nil during `confirmPayment`!")
                wrappedCompletion(.failed, nil, nil)
                return
            }
            if let paymentIntent, error == nil {
                self._handleNextAction(
                    forPayment: paymentIntent,
                    with: authenticationContext,
                    returnURL: params.returnURL
                ) { status, completedPaymentIntent, completedError in
                    wrappedCompletion(status, completedPaymentIntent, completedError)
                }
            } else {
                wrappedCompletion(.failed, paymentIntent, error as NSError?)
            }
        }

        var confirmParams = params
        if !(confirmParams.useStripeSDK ?? false) {
            confirmParams = params.copy() as! STPPaymentIntentConfirmParams
            confirmParams.useStripeSDK = true
        }
        apiClient.confirmPaymentIntent(with: confirmParams, expand: ["payment_method"], completion: confirmCompletionBlock)
    }

    func _handleNextActionForHashedValueImpl(
        hashedValue: String,
        authenticationContext: STPAuthenticationContext,
        returnURL: String?,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        guard subhandler == nil else {
            stpAssertionFailure("`STPPaymentHandler.handleNextAction(forPaymentHashedValue:with:completion:)` was called while a previous call is still in progress.")
            completion(.failed, nil, _error(for: .noConcurrentActionsErrorCode))
            return
        }
        // hashedValue is a base64 encoded string in "pk_test_123:pi_123_secret_abc" format

        // Strip out any newlines or "\n" before decoding
        let hashedValue = hashedValue.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(
            of: "\n",
            with: ""
        )

        guard let decodedData = Data(base64Encoded: hashedValue),
              let decodedString = String(data: decodedData, encoding: .utf8) else {
            completion(.failed, nil, _error(for: .invalidClientSecret))
            return
        }

        // Parse the decoded string to extract publishable key and client secret
        let components = decodedString.components(separatedBy: ":")
        guard components.count >= 2 else {
            completion(.failed, nil, _error(for: .invalidClientSecret))
            return
        }

        let publishableKey = components[0]
        let clientSecret = components[1..<components.count].joined(separator: ":")

        // Create a new API client with the publishable key
        let apiClient = STPAPIClient(publishableKey: publishableKey)

        // Create a new payment handler with the new API client
        let subhandler = STPPaymentHandler(apiClient: apiClient, threeDSCustomizationSettings: self.threeDSCustomizationSettings)

        // Use the new handler to handle the next action
        subhandler.handleNextAction(
            paymentIntentClientSecret: clientSecret,
            authenticationContext: authenticationContext,
            returnURL: returnURL,
            completion: { action, paymentIntent, error in
                completion(action, paymentIntent, error)
                // Clean up the subhandler
                self.subhandler = nil
            }
        )
        // Retain the subhandler during the confirmation
        self.subhandler = subhandler
    }

    func _handleNextActionForPaymentIntentClientSecretImpl(
        clientSecret: String,
        authenticationContext: STPAuthenticationContext,
        returnURL: String?,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        let paymentIntentID = STPPaymentIntent.id(fromClientSecret: clientSecret)
        // Overwrite completion to send an analytic before calling the caller-supplied completion
        let completion: STPPaymentHandlerActionPaymentIntentCompletionBlock = { [weak self] status, paymentIntent, error in
            self?.logHandleNextActionFinished(intentID: paymentIntentID, paymentMethod: paymentIntent?.paymentMethod, status: status, error: error)
            completion(status, paymentIntent, error)
        }
        logHandleNextActionStarted(intentID: paymentIntentID, paymentMethod: nil)
        if !STPPaymentIntentConfirmParams.isClientSecretValid(clientSecret) {
            assertionFailure("`STPPaymentHandler.handleNextAction` was called with an invalid client secret. See https://docs.stripe.com/api/payment_intents/object#payment_intent_object-client_secret")
            completion(.failed, nil, _error(for: .invalidClientSecret))
            return
        }
        apiClient.retrievePaymentIntent(
            withClientSecret: clientSecret,
            expand: ["payment_method"]
        ) { [weak self] paymentIntent, error in
            guard let self else {
                return
            }
            if let paymentIntent = paymentIntent, error == nil {
                self._handleNextActionForPaymentIntentImpl(paymentIntent: paymentIntent, authenticationContext: authenticationContext, returnURL: returnURL, shouldSendAnalytic: false, completion: completion)
            } else {
                completion(.failed, paymentIntent, error as NSError?)
            }
        }
    }

    func _handleNextActionForPaymentIntentImpl(
        paymentIntent: STPPaymentIntent,
        authenticationContext: STPAuthenticationContext,
        returnURL: String?,
        shouldSendAnalytic: Bool = true,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        let paymentIntentID = paymentIntent.stripeId
        let paymentMethod = paymentIntent.paymentMethod
        if shouldSendAnalytic {
            logHandleNextActionStarted(intentID: paymentIntentID, paymentMethod: paymentMethod)
        }

        let completion: STPPaymentHandlerActionPaymentIntentCompletionBlock = { [weak self] status, paymentIntent, error in
            if shouldSendAnalytic {
                self?.logHandleNextActionFinished(intentID: paymentIntentID, paymentMethod: paymentMethod, status: status, error: error)
            }
            completion(status, paymentIntent, error)
        }

        if isProcessing {
            assertionFailure("`STPPaymentHandler.handleNextAction` was called while a previous call is still in progress.")
            completion(.failed, nil, _error(for: .noConcurrentActionsErrorCode))
            return
        }
        if paymentIntent.paymentMethodId != nil {
            assert(paymentIntent.paymentMethod != nil, "A PaymentIntent w/ attached paymentMethod must be retrieved w/ an expanded PaymentMethod")
        }

        isProcessing = true
        let wrappedCompletion = makePaymentIntentWrappedCompletion(includeRequiresConfirmation: true, completion: completion)

        if paymentIntent.status == .requiresConfirmation {
            wrappedCompletion(
                .failed,
                paymentIntent,
                _error(for: .intentStatusErrorCode, loggingSafeErrorMessage: "Confirm the PaymentIntent on the backend before calling handleNextActionForPayment:withAuthenticationContext:completion.")
            )
        } else {
            _handleNextAction(forPayment: paymentIntent, with: authenticationContext, returnURL: returnURL) { status, completedPaymentIntent, completedError in
                wrappedCompletion(status, completedPaymentIntent, completedError)
            }
        }
    }
}

// MARK: - SetupIntent API Implementation

extension STPPaymentHandler {

    func _confirmSetupIntentImpl(
        params: STPSetupIntentConfirmParams,
        authenticationContext: STPAuthenticationContext,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        let setupIntentID = STPSetupIntent.id(fromClientSecret: params.clientSecret)
        logConfirmSetupIntentStarted(setupIntentID: setupIntentID, confirmParams: params)

        let completion: STPPaymentHandlerActionSetupIntentCompletionBlock = { [weak self] status, setupIntent, error in
            self?.logConfirmSetupIntentCompleted(setupIntentID: setupIntentID, confirmParams: params, status: status, error: error)
            completion(status, setupIntent, error)
        }

        if let error = validateCanBeginAction(
            clientSecret: params.clientSecret,
            isClientSecretValid: STPSetupIntentConfirmParams.isClientSecretValid,
            methodName: "STPPaymentHandler.confirmSetupIntent"
        ) {
            completion(.failed, nil, error)
            return
        }

        isProcessing = true
        let wrappedCompletion = makeSetupIntentWrappedCompletion(completion: completion)

        let confirmCompletionBlock: STPSetupIntentCompletionBlock = { [weak self] setupIntent, error in
            guard let self else { return }

            if let setupIntent, error == nil {
                let action = STPPaymentHandlerSetupIntentActionParams(
                    apiClient: self.apiClient,
                    authenticationContext: authenticationContext,
                    threeDSCustomizationSettings: self.threeDSCustomizationSettings,
                    setupIntent: setupIntent,
                    returnURL: params.returnURL
                ) { [weak self] status, resultSetupIntent, resultError in
                    self?.currentAction = nil
                    wrappedCompletion(status, resultSetupIntent, resultError)
                }
                self.currentAction = action
                let requiresAction = self._handleSetupIntentStatus(forAction: action)
                if requiresAction {
                    self._handleAuthenticationForCurrentAction()
                }
            } else {
                wrappedCompletion(.failed, setupIntent, error as NSError?)
            }
        }

        var confirmParams = params
        if !(confirmParams.useStripeSDK ?? false) {
            confirmParams = params.copy() as! STPSetupIntentConfirmParams
            confirmParams.useStripeSDK = true
        }
        apiClient.confirmSetupIntent(with: confirmParams, expand: ["payment_method"], completion: confirmCompletionBlock)
    }

    func _handleNextActionForSetupIntentClientSecretImpl(
        clientSecret: String,
        authenticationContext: STPAuthenticationContext,
        returnURL: String?,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        let setupIntentID = STPSetupIntent.id(fromClientSecret: clientSecret)
        // Overwrite completion to send an analytic before calling the caller-supplied completion
        let completion: STPPaymentHandlerActionSetupIntentCompletionBlock = { [weak self] status, setupIntent, error in
            self?.logHandleNextActionFinished(intentID: setupIntentID, paymentMethod: setupIntent?.paymentMethod, status: status, error: error)
            completion(status, setupIntent, error)
        }
        logHandleNextActionStarted(intentID: setupIntentID, paymentMethod: nil)

        if !STPSetupIntentConfirmParams.isClientSecretValid(clientSecret) {
            assertionFailure("`STPPaymentHandler.handleNextAction` was called with an invalid client secret. See https://docs.stripe.com/api/payment_intents/object#setup_intent_object-client_secret")
            completion(.failed, nil, _error(for: .invalidClientSecret))
            return
        }

        apiClient.retrieveSetupIntent(withClientSecret: clientSecret, expand: ["payment_method"]) { [weak self] setupIntent, error in
            guard let self else {
                return
            }
            if let setupIntent, error == nil {
                self._handleNextActionForSetupIntentImpl(setupIntent: setupIntent, authenticationContext: authenticationContext, returnURL: returnURL, shouldSendAnalytic: false, completion: completion)
            } else {
                completion(.failed, setupIntent, error as NSError?)
            }
        }
    }

    func _handleNextActionForSetupIntentImpl(
        setupIntent: STPSetupIntent,
        authenticationContext: STPAuthenticationContext,
        returnURL: String?,
        shouldSendAnalytic: Bool = true,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        let setupIntentID = setupIntent.stripeID
        let paymentMethod = setupIntent.paymentMethod
        if shouldSendAnalytic {
            logHandleNextActionStarted(intentID: setupIntentID, paymentMethod: paymentMethod)
        }

        let completion: STPPaymentHandlerActionSetupIntentCompletionBlock = { [weak self] status, setupIntent, error in
            if shouldSendAnalytic {
                self?.logHandleNextActionFinished(intentID: setupIntentID, paymentMethod: paymentMethod, status: status, error: error)
            }
            completion(status, setupIntent, error)
        }

        if isProcessing {
            assertionFailure("`STPPaymentHandler.handleNextAction` was called while a previous call is still in progress.")
            completion(.failed, nil, _error(for: .noConcurrentActionsErrorCode))
            return
        }
        if setupIntent.paymentMethodID != nil {
            assert(setupIntent.paymentMethod != nil, "A SetupIntent w/ attached paymentMethod must be retrieved w/ an expanded PaymentMethod")
        }

        isProcessing = true
        let wrappedCompletion = makeSetupIntentWrappedCompletion(completion: completion)

        if setupIntent.status == .requiresConfirmation {
            wrappedCompletion(
                .failed,
                setupIntent,
                _error(for: .intentStatusErrorCode, loggingSafeErrorMessage: "Confirm the SetupIntent on the backend before calling handleNextActionForSetupIntent:withAuthenticationContext:completion.")
            )
        } else {
            _handleNextAction(for: setupIntent, with: authenticationContext, returnURL: returnURL) { status, completedSetupIntent, completedError in
                wrappedCompletion(status, completedSetupIntent, completedError)
            }
        }
    }
}
