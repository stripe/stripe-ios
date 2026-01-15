//
//  ThreeDS2AuthenticationHandler.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

#if canImport(Stripe3DS2)
import Stripe3DS2
#endif

/// Handles 3DS2 authentication actions.
///
/// This includes:
/// - 3DS2 fingerprint authentication
/// - 3DS2 redirect fallback
/// - Intent confirmation challenges
///
/// Note: The challenge status receiver callbacks remain on `STPPaymentHandler`
/// since they require access to the payment handler's state for completion.
final class ThreeDS2AuthenticationHandler: AuthenticationHandler {

    func canHandle(actionType: STPIntentActionType) -> Bool {
        return actionType == .useStripeSDK
    }

    func handle(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let useStripeSDK = action.useStripeSDK else {
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "Authentication action useStripeSDK is missing expected details."
                )
            )
            return
        }

        switch useStripeSDK.type {
        case .unknown:
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "Unexpected useStripeSDK type"
                )
            )

        case .threeDS2Fingerprint:
            handleThreeDS2Fingerprint(
                useStripeSDK: useStripeSDK,
                currentAction: currentAction,
                paymentHandler: paymentHandler
            )

        case .threeDS2Redirect:
            handleThreeDS2Redirect(
                useStripeSDK: useStripeSDK,
                currentAction: currentAction,
                paymentHandler: paymentHandler
            )

        case .intentConfirmationChallenge:
            paymentHandler._handleIntentConfirmationChallenge()
        }
    }

    // MARK: - 3DS2 Fingerprint

    private func handleThreeDS2Fingerprint(
        useStripeSDK: STPIntentActionUseStripeSDK,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let threeDSService = currentAction.threeDS2Service else {
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .stripe3DS2ErrorCode,
                    loggingSafeErrorMessage: "Failed to initialize STDSThreeDS2Service."
                )
            )
            return
        }

        var transaction: STDSTransaction?
        var authRequestParams: STDSAuthenticationRequestParameters?

        STDSSwiftTryCatch.try(
            {
                transaction = threeDSService.createTransaction(
                    forDirectoryServer: useStripeSDK.directoryServerID ?? "",
                    serverKeyID: useStripeSDK.directoryServerKeyID,
                    certificateString: useStripeSDK.directoryServerCertificate ?? "",
                    rootCertificateStrings: useStripeSDK.rootCertificateStrings ?? [],
                    withProtocolVersion: "2.2.0"
                )
                authRequestParams = transaction?.createAuthenticationRequestParameters()
            },
            catch: { [weak self] exception in
                guard let self else { return }

                paymentHandler.analyticsClient.log3DS2AuthenticationRequestParamsFailed(
                    intentID: currentAction.intentStripeID,
                    error: self.createError(
                        for: .stripe3DS2ErrorCode,
                        loggingSafeErrorMessage: exception.description
                    )
                )

                currentAction.complete(
                    with: .failed,
                    error: self.createError(
                        for: .stripe3DS2ErrorCode,
                        loggingSafeErrorMessage: exception.description
                    )
                )
            },
            finallyBlock: {}
        )

        paymentHandler.analyticsClient.log3DS2AuthenticateAttempt(
            intentID: currentAction.intentStripeID
        )

        guard let authParams = authRequestParams, let transaction else {
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .stripe3DS2ErrorCode,
                    loggingSafeErrorMessage: transaction == nil ? "Missing transaction." : "Missing auth request params."
                )
            )
            return
        }

        currentAction.threeDS2Transaction = transaction

        currentAction.apiClient.authenticate3DS2(
            authParams,
            sourceIdentifier: useStripeSDK.threeDSSourceID ?? "",
            returnURL: currentAction.returnURLString,
            maxTimeout: currentAction.threeDSCustomizationSettings.authenticationTimeout,
            publishableKeyOverride: useStripeSDK.publishableKeyOverride
        ) { [weak self] authenticateResponse, error in
            guard let self else { return }

            self.handleAuthenticateResponse(
                authenticateResponse: authenticateResponse,
                error: error,
                transaction: transaction,
                currentAction: currentAction,
                paymentHandler: paymentHandler
            )
        }
    }

    private func handleAuthenticateResponse(
        authenticateResponse: STP3DS2AuthenticateResponse?,
        error: Error?,
        transaction: STDSTransaction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let authenticateResponse else {
            let error = error ?? createError(
                for: .stripe3DS2ErrorCode,
                loggingSafeErrorMessage: "Missing authenticate response"
            )
            currentAction.complete(with: .failed, error: error as NSError)
            return
        }

        guard error == nil else {
            currentAction.complete(with: .failed, error: error! as NSError)
            return
        }

        if let aRes = authenticateResponse.authenticationResponse {
            if aRes.isChallengeRequired {
                presentChallenge(
                    challengeParameters: STDSChallengeParameters(authenticationResponse: aRes),
                    transaction: transaction,
                    currentAction: currentAction,
                    paymentHandler: paymentHandler
                )
            } else {
                // Challenge not required, finish the flow.
                transaction.close()
                currentAction.threeDS2Transaction = nil
                paymentHandler.analyticsClient.log3DS2FrictionlessFlow(
                    intentID: currentAction.intentStripeID
                )
                paymentHandler._retrieveAndCheckIntentForCurrentAction()
            }
        } else if let fallbackURL = authenticateResponse.fallbackURL {
            paymentHandler._handleRedirect(
                to: fallbackURL,
                withReturn: URL(string: currentAction.returnURLString ?? ""),
                useWebAuthSession: false
            )
        } else {
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "3DS2 authenticate response missing both response and fallback URL."
                )
            )
        }
    }

    private func presentChallenge(
        challengeParameters: STDSChallengeParameters,
        transaction: STDSTransaction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        let doChallenge: STPVoidBlock = { [weak self] in
            guard let self else { return }

            var presentationError: NSError?
            guard paymentHandler._canPresent(
                with: currentAction.authenticationContext,
                error: &presentationError
            ) else {
                currentAction.complete(with: .failed, error: presentationError)
                return
            }

            STDSSwiftTryCatch.try({
                let presentingViewController = currentAction.authenticationContext.authenticationPresentingViewController()
                let timeout = TimeInterval(currentAction.threeDSCustomizationSettings.authenticationTimeout * 60)

                if let paymentSheet = presentingViewController as? PaymentSheetAuthenticationContext {
                    transaction.doChallenge(
                        with: challengeParameters,
                        challengeStatusReceiver: paymentHandler,
                        timeout: timeout
                    ) { threeDSChallengeViewController, completion in
                        paymentSheet.present(threeDSChallengeViewController, completion: completion)
                    }
                } else {
                    transaction.doChallenge(
                        with: presentingViewController,
                        challengeParameters: challengeParameters,
                        challengeStatusReceiver: paymentHandler,
                        timeout: timeout
                    )
                }
            }, catch: { exception in
                paymentHandler.currentAction?.complete(
                    with: .failed,
                    error: self.createError(
                        for: .stripe3DS2ErrorCode,
                        loggingSafeErrorMessage: exception.description
                    )
                )
            }, finallyBlock: {})
        }

        if currentAction.authenticationContext.responds(
            to: #selector(STPAuthenticationContext.prepare(forPresentation:))
        ) {
            currentAction.authenticationContext.prepare?(forPresentation: doChallenge)
        } else {
            doChallenge()
        }
    }

    // MARK: - 3DS2 Redirect

    private func handleThreeDS2Redirect(
        useStripeSDK: STPIntentActionUseStripeSDK,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let redirectURL = useStripeSDK.redirectURL else {
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "Next action type is threeDS2Redirect but missing redirect URL."
                )
            )
            return
        }

        let returnURL: URL?
        if let returnURLString = currentAction.returnURLString {
            returnURL = URL(string: returnURLString)
        } else {
            returnURL = nil
        }

        paymentHandler._handleRedirect(to: redirectURL, withReturn: returnURL, useWebAuthSession: false)
    }
}
