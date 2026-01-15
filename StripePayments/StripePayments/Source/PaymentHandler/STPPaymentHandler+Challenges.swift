//
//  STPPaymentHandler+Challenges.swift
//  StripePayments
//
//  Extracted from STPPaymentHandler.swift for modularity.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

// MARK: - Challenge Handling

extension STPPaymentHandler {

    /// Handles intent confirmation challenge by presenting a WebView with the Stripe-hosted challenge page
    func _handleIntentConfirmationChallenge() {
        guard let currentAction else {
            stpAssertionFailure("Calling _handleIntentConfirmationChallenge without a currentAction")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling _handleIntentConfirmationChallenge without a currentAction"])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }

        if #available(iOS 14.0, *) {
            // Extract client secret
            let clientSecret: String
            if let piAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams {
                clientSecret = piAction.paymentIntent.clientSecret
            } else if let siAction = currentAction as? STPPaymentHandlerSetupIntentActionParams {
                clientSecret = siAction.setupIntent.clientSecret
            } else {
                currentAction.complete(
                    with: .failed,
                    error: _error(
                        for: .unexpectedErrorCode,
                        loggingSafeErrorMessage: "Unable to extract client secret for intent confirmation challenge"
                    )
                )
                return
            }

            // Extract publishable key
            guard let publishableKey = apiClient.publishableKey else {
                currentAction.complete(
                    with: .failed,
                    error: _error(
                        for: .unexpectedErrorCode,
                        loggingSafeErrorMessage: "Unable to extract publishable key for intent confirmation challenge"
                    )
                )
                return
            }

            let context = currentAction.authenticationContext
            var presentationError: NSError?
            guard _canPresent(with: context, error: &presentationError) else {
                currentAction.complete(with: .failed, error: presentationError)
                return
            }

            let presentingVC = context.authenticationPresentingViewController()

                let challengeVC = IntentConfirmationChallengeViewController(
                    publishableKey: publishableKey,
                    clientSecret: clientSecret
                ) { [weak self] result in
                    guard let self = self else { return }

                    // Dismiss the challenge view
                    presentingVC.dismiss(animated: true) {
                        switch result {
                        case .success:
                            // The web page handled the next action via Stripe.js
                            // Now retrieve the updated intent to check its status
                            self._retrieveAndCheckIntentForCurrentAction()

                        case .failure(let error):
                            currentAction.complete(with: .failed, error: error as NSError)
                        }
                    }
                }

            let doChallenge: STPVoidBlock = {
                challengeVC.modalPresentationStyle = .overFullScreen
                challengeVC.modalTransitionStyle = .crossDissolve
                presentingVC.present(challengeVC, animated: true, completion: nil)
            }

            if context.responds(to: #selector(STPAuthenticationContext.prepare(forPresentation:))) {
                context.prepare?(forPresentation: doChallenge)
            } else {
                doChallenge()
            }
        } else { // Intent confirmation challenge should be gated to iOS versions 14.0+
            let unsupportedVersionErrorMessage = "Unable to perform intent confirmation challenge. Requires iOS version 14.0 or later."
            stpAssertionFailure(unsupportedVersionErrorMessage)
            currentAction.complete(
                with: .failed,
                error: _error(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: unsupportedVersionErrorMessage
                )
            )
        }
    }

    /// Checks if authenticationContext.authenticationPresentingViewController can be presented on.
    /// @note Call this method after `prepareAuthenticationContextForPresentation:`
    func _canPresent(
        with authenticationContext: STPAuthenticationContext,
        error: inout NSError?
    )
        -> Bool
    {
        // Always allow in tests:
        if NSClassFromString("XCTest") != nil {
            return true
        }
        let presentingViewController =
            authenticationContext.authenticationPresentingViewController()
        var canPresent = true
        var loggingSafeErrorMessage: String?

        // Is it in the window hierarchy?
        if presentingViewController.viewIfLoaded?.window == nil {
            canPresent = false
            loggingSafeErrorMessage =
                "authenticationPresentingViewController is not in the window hierarchy. You should probably return the top-most view controller instead."
        }

        // Is it already presenting something?
        if presentingViewController.presentedViewController != nil {
            canPresent = false
            loggingSafeErrorMessage =
                "authenticationPresentingViewController is already presenting. You should probably dismiss the presented view controller in `prepareAuthenticationContextForPresentation`."
        }

        if !canPresent {
            error = _error(
                for: .requiresAuthenticationContextErrorCode,
                loggingSafeErrorMessage: loggingSafeErrorMessage
            )
        }
        return canPresent
    }

    // This is only called after web-redirects because native 3DS2 cancels go directly
    // to the ACS
    func _markChallengeCanceled(currentAction: STPPaymentHandlerActionParams, completion: @escaping STPBooleanSuccessBlock) {
        guard let nextAction = currentAction.nextAction() else {
            stpAssert(false, "Calling _markChallengeCanceled without nextAction.")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling _markChallengeCanceled without nextAction."])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }

        var threeDSSourceID: String?
        switch nextAction.type {
        case .redirectToURL:
            threeDSSourceID = nextAction.redirectToURL?.threeDSSourceID
        case .useStripeSDK:
            threeDSSourceID = nextAction.useStripeSDK?.threeDSSourceID
        case .OXXODisplayDetails, .alipayHandleRedirect, .unknown, .BLIKAuthorize,
            .weChatPayRedirectToApp, .boletoDisplayDetails, .verifyWithMicrodeposits,
            .upiAwaitNotification, .cashAppRedirectToApp, .konbiniDisplayDetails, .payNowDisplayQrCode,
            .promptpayDisplayQrCode, .swishHandleRedirect, .multibancoDisplayDetails:
            break
        }

        guard let cancelSourceID = threeDSSourceID else {
            // If there's no threeDSSourceID, there's nothing for us to cancel
            completion(true, nil)
            return
        }

        if let currentAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams {
            guard
                currentAction.paymentIntent.paymentMethod?.card != nil || currentAction.paymentIntent.paymentMethod?.link != nil
            else {
                // Only cancel 3DS auth on payment method types that support 3DS.
                completion(true, nil)
                return
            }

            analyticsClient.log3DS2RedirectUserCanceled(
                intentID: currentAction.intentStripeID
            )

            let intentID = nextAction.useStripeSDK?.threeDS2IntentOverride ?? currentAction.paymentIntent.stripeId

            currentAction.apiClient.cancel3DSAuthentication(
                forPaymentIntent: intentID,
                withSource: cancelSourceID,
                publishableKeyOverride: nextAction.useStripeSDK?.publishableKeyOverride
            ) { paymentIntent, error in
                if let paymentIntent {
                    currentAction.paymentIntent = paymentIntent
                }
                completion(paymentIntent != nil, error)
            }
        } else if let currentAction = currentAction as? STPPaymentHandlerSetupIntentActionParams {
            let setupIntent = currentAction.setupIntent
            guard setupIntent.paymentMethod?.card != nil || setupIntent.paymentMethod?.link != nil
            else {
                // Only cancel 3DS auth on payment method types that support 3DS.
                completion(true, nil)
                return
            }

            analyticsClient.log3DS2RedirectUserCanceled(
                intentID: currentAction.intentStripeID
            )

            let intentID = nextAction.useStripeSDK?.threeDS2IntentOverride ?? setupIntent.stripeID

            currentAction.apiClient.cancel3DSAuthentication(
                forSetupIntent: intentID,
                withSource: cancelSourceID,
                publishableKeyOverride: nextAction.useStripeSDK?.publishableKeyOverride
            ) { retrievedSetupIntent, error in
                if let retrievedSetupIntent {
                    currentAction.setupIntent = retrievedSetupIntent
                }
                completion(retrievedSetupIntent != nil, error)
            }
        } else {
            // TODO: Make currentAction an enum, stop optionally casting it
            stpAssert(false, "currentAction is an unknown type or nil intent.")
            currentAction.complete(
                with: .failed,
                error: _error(for: .unexpectedErrorCode, loggingSafeErrorMessage: "currentAction is an unknown type or nil intent.")
            )
        }
    }

    static let maxChallengeRetries = 5
    func _markChallengeCompleted(
        withCompletion completion: @escaping STPBooleanSuccessBlock,
        retryCount: Int = maxChallengeRetries
    ) {
        guard let currentAction,
              let useStripeSDK = currentAction.nextAction()?.useStripeSDK,
              let threeDSSourceID = useStripeSDK.threeDSSourceID
        else {
            let errorMessage: String = {
                if currentAction == nil {
                    return "Attempted to mark challenge completed, but currentAction is nil"
                } else if currentAction?.nextAction()?.useStripeSDK == nil {
                    return "Attempted to mark challenge completed, but useStripeSDK is nil"
                } else {
                    return "Attempted to mark challenge completed, but threeDSSourceID is nil"
                }
            }()
            stpAssertionFailure(errorMessage)
            completion(false, self._error(for: .unexpectedErrorCode, loggingSafeErrorMessage: errorMessage))
            return
        }

        func retrieveIntent(action: STPPaymentHandlerActionParams, completion: @escaping STPBooleanSuccessBlock) {
            if let paymentIntentAction = action as? STPPaymentHandlerPaymentIntentActionParams {
                currentAction.apiClient.retrievePaymentIntent(
                    withClientSecret: paymentIntentAction.paymentIntent.clientSecret,
                    expand: ["payment_method"]
                ) { paymentIntent, retrieveError in
                    if let paymentIntent {
                        paymentIntentAction.paymentIntent = paymentIntent
                    }
                    completion(paymentIntent != nil, retrieveError)
                }
            } else if let setupIntentAction = action as? STPPaymentHandlerSetupIntentActionParams {
                currentAction.apiClient.retrieveSetupIntent(
                    withClientSecret: setupIntentAction.setupIntent.clientSecret,
                    expand: ["payment_method"]
                ) { retrievedSetupIntent, retrieveError in
                    if let retrievedSetupIntent {
                        setupIntentAction.setupIntent = retrievedSetupIntent
                    }
                    completion(retrievedSetupIntent != nil, retrieveError)
                }
            } else {
                // TODO: Make currentAction an enum, stop optionally casting it
                stpAssert(false, "currentAction is an unknown type or nil intent.")
                currentAction.complete(
                    with: .failed,
                    error: self._error(for: .unexpectedErrorCode, loggingSafeErrorMessage: "currentAction is an unknown type or nil intent.")
                )
            }
        }

        currentAction.apiClient.complete3DS2Authentication(
            forSource: threeDSSourceID,
            publishableKeyOverride: useStripeSDK.publishableKeyOverride
        ) { success, error in
            if success {
               retrieveIntent(action: currentAction, completion: completion)
            } else {
                // This isn't guaranteed to succeed if the ACS isn't ready yet.
                // Try it a few more times if it fails with a 400. (RUN_MOBILESDK-126)
                if retryCount > 0
                    && (error as NSError?)?.code == STPErrorCode.invalidRequestError.rawValue
                {
                    self._retryAfterDelay(
                        retryCount: retryCount,
                        block: {
                            self._markChallengeCompleted(
                                withCompletion: completion,
                                retryCount: retryCount - 1
                            )
                        }
                    )
                } else {
                    // Completing the 3DS2 action failed, try to retrieve the intent anyways:
                    retrieveIntent(action: currentAction, completion: completion)
                }
            }
        }
    }

    func retrieveOrRefreshPaymentIntent(currentAction: STPPaymentHandlerPaymentIntentActionParams,
                                        timeout: NSNumber?,
                                        completion: @escaping STPPaymentIntentCompletionBlock) {
        let paymentMethodType = currentAction.paymentIntent.paymentMethod?.type ?? .unknown

        if paymentMethodType.supportsRefreshing {
            currentAction.apiClient.refreshPaymentIntent(withClientSecret: currentAction.paymentIntent.clientSecret,
                                                         completion: completion)
        } else {
            currentAction.apiClient.retrievePaymentIntent(withClientSecret: currentAction.paymentIntent.clientSecret,
                                                          expand: ["payment_method"],
                                                          timeout: timeout,
                                                          completion: completion)
        }
    }

    func retrieveOrRefreshSetupIntent(currentAction: STPPaymentHandlerSetupIntentActionParams,
                                      timeout: NSNumber?,
                                      completion: @escaping STPSetupIntentCompletionBlock) {
        let paymentMethodType = currentAction.setupIntent.paymentMethod?.type ?? .unknown

        if paymentMethodType.supportsRefreshing {
            currentAction.apiClient.refreshSetupIntent(withClientSecret: currentAction.setupIntent.clientSecret,
                                                       completion: completion)
        } else {
            currentAction.apiClient.retrieveSetupIntent(withClientSecret: currentAction.setupIntent.clientSecret,
                                                        expand: ["payment_method"],
                                                        timeout: timeout,
                                                        completion: completion)
        }
    }
}
