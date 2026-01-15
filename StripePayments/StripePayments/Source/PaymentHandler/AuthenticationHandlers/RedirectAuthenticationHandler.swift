//
//  RedirectAuthenticationHandler.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// Handles authentication actions that require redirecting the user to an external URL or app.
///
/// This includes:
/// - Standard URL redirects (e.g., 3DS1)
/// - Alipay app/web redirects
/// - WeChat Pay app redirects
/// - Cash App redirects
/// - Swish redirects
final class RedirectAuthenticationHandler: AuthenticationHandler {

    private let missingReturnURLErrorMessage = "The payment method requires a return URL and one was not provided. Your integration should provide one in your `STPPaymentIntentConfirmParams`/`STPSetupIntentConfirmParams` object if you call `STPPaymentHandler.confirm...` or when you call  `STPPaymentHandler.handleNextAction`."

    func canHandle(actionType: STPIntentActionType) -> Bool {
        switch actionType {
        case .redirectToURL,
             .alipayHandleRedirect,
             .weChatPayRedirectToApp,
             .cashAppRedirectToApp,
             .swishHandleRedirect:
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
        case .redirectToURL:
            handleRedirectToURL(action: action, currentAction: currentAction, paymentHandler: paymentHandler)

        case .alipayHandleRedirect:
            handleAlipayRedirect(action: action, currentAction: currentAction, paymentHandler: paymentHandler)

        case .weChatPayRedirectToApp:
            handleWeChatPayRedirect(action: action, currentAction: currentAction, paymentHandler: paymentHandler)

        case .cashAppRedirectToApp:
            handleCashAppRedirect(action: action, currentAction: currentAction, paymentHandler: paymentHandler)

        case .swishHandleRedirect:
            handleSwishRedirect(action: action, currentAction: currentAction, paymentHandler: paymentHandler)

        default:
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unsupportedAuthenticationErrorCode,
                    loggingSafeErrorMessage: "RedirectAuthenticationHandler cannot handle action type: \(action.type)"
                )
            )
        }
    }

    // MARK: - Private Handlers

    private func handleRedirectToURL(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let redirectToURL = action.redirectToURL else {
            completeWithMissingDetails(currentAction: currentAction, actionType: action.type)
            return
        }

        let redirectURL = redirectToURL.followRedirects
            ? paymentHandler.followRedirect(to: redirectToURL.url)
            : redirectToURL.url

        paymentHandler._handleRedirect(
            to: redirectURL,
            withReturn: redirectToURL.returnURL,
            useWebAuthSession: redirectToURL.useWebAuthSession
        )
    }

    private func handleAlipayRedirect(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let alipayHandleRedirect = action.alipayHandleRedirect else {
            completeWithMissingDetails(currentAction: currentAction, actionType: action.type)
            return
        }

        paymentHandler._handleRedirect(
            to: alipayHandleRedirect.nativeURL,
            fallbackURL: alipayHandleRedirect.url,
            return: alipayHandleRedirect.returnURL,
            useWebAuthSession: false
        )
    }

    private func handleWeChatPayRedirect(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let weChatPayRedirectToApp = action.weChatPayRedirectToApp else {
            completeWithMissingDetails(currentAction: currentAction, actionType: action.type)
            return
        }

        paymentHandler._handleRedirect(
            to: weChatPayRedirectToApp.nativeURL,
            fallbackURL: nil,
            return: nil,
            useWebAuthSession: false
        )
    }

    private func handleCashAppRedirect(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let returnURL = URL(string: currentAction.returnURLString ?? "") else {
            assertionFailure(missingReturnURLErrorMessage)
            currentAction.complete(
                with: .failed,
                error: createError(for: .missingReturnURL)
            )
            return
        }

        guard let mobileAuthURL = action.cashAppRedirectToApp?.mobileAuthURL else {
            completeWithMissingDetails(currentAction: currentAction, actionType: action.type)
            return
        }

        paymentHandler._handleRedirect(
            to: mobileAuthURL,
            fallbackURL: mobileAuthURL,
            return: returnURL,
            useWebAuthSession: false
        )
    }

    private func handleSwishRedirect(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        guard let returnURL = URL(string: currentAction.returnURLString ?? "") else {
            assertionFailure(missingReturnURLErrorMessage)
            currentAction.complete(
                with: .failed,
                error: createError(for: .missingReturnURL)
            )
            return
        }

        guard let mobileAuthURL = action.swishHandleRedirect?.mobileAuthURL else {
            completeWithMissingDetails(currentAction: currentAction, actionType: action.type)
            return
        }

        paymentHandler._handleRedirect(
            to: mobileAuthURL,
            withReturn: returnURL,
            useWebAuthSession: false
        )
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
