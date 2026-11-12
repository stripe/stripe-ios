//
//  NextActionPerformer.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
import SafariServices
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
import UIKit

/// What happened when a next action was performed.
enum NextActionOutcome {
    /// The customer came back. `PaymentConfirmer` fetches the intent and evaluates it.
    /// - Parameter screen: A screen still showing that may finish the payment (the polling screen behind a web view).
    case returned(RedirectReturnType, screen: NextActionScreen?)
    /// Nothing more to show (microdeposits): `PaymentConfirmer` evaluates the intent as it is, without a fetch.
    case performed
    /// The performer finished the payment itself: the polling screen, STPPaymentHandler, or a failure to perform.
    /// The metadata isn't consulted.
    case finished(PaymentSheetResult, ConfirmingIntent?)
}

/// A screen that's still showing after its next action returned, and may finish the payment.
@MainActor
protocol NextActionScreen: AnyObject {
    /// Waits for the screen to finish the payment.
    func result() async -> (PaymentSheetResult, ConfirmingIntent?)
    /// The payment finished without the screen: stop it, and take it off screen unless the payment succeeded (the
    /// sheet closes then anyway).
    func stop(dismiss: Bool)
}

/// Performs the next action primitives for `PaymentConfirmer`. Tests and the parity harness record instead.
@MainActor
protocol NextActionPerforming {
    /// - Parameters:
    ///   - returnURL: The confirm request's `return_url`, for STPPaymentHandler.
    ///   - actionID: The payment's `action_id`, for STPPaymentHandler's own analytics.
    ///   - poll: Reads the intent once, for the polling screen.
    ///   - didOpen: Called when an app or web view opens, for analytics.
    func perform(
        _ action: ResolvedNextAction,
        intent: ConfirmingIntent,
        returnURL: String?,
        actionID: String,
        authenticationContext: STPAuthenticationContext,
        poll: @escaping () async -> ConfirmingIntent?,
        didOpen: @escaping (RedirectType) -> Void
    ) async -> NextActionOutcome
}

/// The real primitives: the redirect presenter, the polling screen, nothing, and STPPaymentHandler for `use_stripe_sdk`
/// and for card and Link.
@MainActor
final class PaymentSheetNextActionPerformer: NextActionPerforming {
    /// The surface's own STPPaymentHandler, not a new one: the sheet's close button cancels a 3DS2 challenge through
    /// `paymentHandler.cancel3DS2ChallengeFlow()`, which needs the transaction this instance started.
    let paymentHandler: STPPaymentHandler
    private let makeRedirectPresenter: @MainActor () -> RedirectPresenting

    /// Tests: replaces the redirect presenter of every payment, like STPPaymentHandler's `_redirectShim`.
    nonisolated(unsafe) static var _testMakeRedirectPresenter: (@MainActor () -> RedirectPresenting)?

    init(paymentHandler: STPPaymentHandler, makeRedirectPresenter: (@MainActor () -> RedirectPresenting)? = nil) {
        self.paymentHandler = paymentHandler
        self.makeRedirectPresenter = makeRedirectPresenter ?? Self._testMakeRedirectPresenter ?? { [paymentHandler] in
            RedirectNextActionPresenter(simulateAppToAppRedirect: paymentHandler.simulateAppToAppRedirect)
        }
    }

    func perform(
        _ action: ResolvedNextAction,
        intent: ConfirmingIntent,
        returnURL: String?,
        actionID: String,
        authenticationContext: STPAuthenticationContext,
        poll: @escaping () async -> ConfirmingIntent?,
        didOpen: @escaping (RedirectType) -> Void
    ) async -> NextActionOutcome {
        switch action {
        case .redirect(let redirect):
            switch await makeRedirectPresenter().redirect(redirect, authenticationContext: authenticationContext, didOpen: didOpen, didPresent: nil) {
            case .returned(let returnType):
                return .returned(returnType, screen: nil)
            case .failed(let error):
                return .finished(.failed(error: error), nil)
            }
        case .pollingScreen(let pollingScreen):
            return await PollingScreenSession.perform(pollingScreen, intent: intent, authenticationContext: authenticationContext, redirectPresenter: makeRedirectPresenter(), poll: poll, didOpen: didOpen)
        case .none:
            return .performed
        case .stripeSDK:
            return await performWithPaymentHandler(intent: intent, returnURL: returnURL, actionID: actionID, authenticationContext: authenticationContext)
        }
    }

    /// Hands the payment to STPPaymentHandler, which performs the next action (3DS2, the 3DS redirect, the intent
    /// confirmation challenge, or any next action of card and Link) and applies its own rules after it.
    /// `shouldSendAnalytic: false`, because PaymentConfirmer logs the confirm and handle_next_action events itself; the
    /// events STPPaymentHandler still logs (redirects, polling timeouts) carry PaymentConfirmer's `action_id`.
    private func performWithPaymentHandler(intent: ConfirmingIntent, returnURL: String?, actionID: String, authenticationContext: STPAuthenticationContext) async -> NextActionOutcome {
        switch intent {
        case .paymentIntent(let paymentIntent):
            return await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(for: paymentIntent, with: authenticationContext, returnURL: returnURL, shouldSendAnalytic: false, actionID: actionID) { status, paymentIntent, error in
                    continuation.resume(returning: .finished(PaymentSheet.makePaymentSheetResult(for: status, error: error), paymentIntent.map { .paymentIntent($0) }))
                }
            }
        case .setupIntent(let setupIntent):
            return await withCheckedContinuation { continuation in
                paymentHandler.handleNextAction(for: setupIntent, with: authenticationContext, returnURL: returnURL, shouldSendAnalytic: false, actionID: actionID) { status, setupIntent, error in
                    continuation.resume(returning: .finished(PaymentSheet.makePaymentSheetResult(for: status, error: error), setupIntent.map { .setupIntent($0) }))
                }
            }
        }
    }
}

// MARK: - Polling screen

/// One polling screen: shows `PollingViewController`, optionally behind the hosted instructions web view, and reports
/// how it finished.
@MainActor
final class PollingScreenSession: NextActionScreen {
    private weak var viewController: PollingViewController?
    private weak var host: PollingScreenHosting?
    private var latestIntent: ConfirmingIntent?
    private var finalResult: PaymentSheetResult?
    private var waiters: [CheckedContinuation<(PaymentSheetResult, ConfirmingIntent?), Never>] = []
    /// Called once when the screen finishes the payment.
    var onFinish: (() -> Void)?

    static func perform(
        _ pollingScreen: ResolvedNextAction.PollingScreen,
        intent: ConfirmingIntent,
        authenticationContext: STPAuthenticationContext,
        redirectPresenter: RedirectPresenting,
        poll: @escaping () async -> ConfirmingIntent?,
        didOpen: @escaping (RedirectType) -> Void
    ) async -> NextActionOutcome {
        guard let host = authenticationContext as? PollingScreenHosting else {
            // STPPaymentHandler: "<type> is not supported outside of PaymentSheet" (BLIK alone succeeds right away there).
            return .finished(.failed(error: PaymentConfirmer.error(.unsupportedAuthenticationErrorCode, loggingSafeErrorMessage: "The polling screen needs a PaymentSheet container")), nil)
        }
        let session = PollingScreenSession(host: host, intent: intent)
        guard let instructions = pollingScreen.instructions else {
            // BLIK, MB WAY, Bizum: just the screen, which finishes the payment.
            session.present(pollingScreen, poll: poll, safariViewController: nil)
            let (result, finalIntent) = await session.result()
            return .finished(result, finalIntent)
        }

        // PayNow, PromptPay, Pix: the instructions in a web view, with the screen behind it so it polls right away.
        // Whichever finishes first decides: the screen finishing the payment, or the customer closing the web view.
        enum Event {
            case webView(RedirectResult)
            case screenFinished
        }
        return await withCheckedContinuation { (continuation: CheckedContinuation<NextActionOutcome, Never>) in
            var resumed = false
            let resume: (Event) -> Void = { event in
                guard !resumed else { return }
                resumed = true
                switch event {
                case .webView(.returned(let returnType)):
                    continuation.resume(returning: .returned(returnType, screen: session))
                case .webView(.failed(let error)):
                    session.stop(dismiss: true)
                    continuation.resume(returning: .finished(.failed(error: error), nil))
                case .screenFinished:
                    // The customer paid elsewhere while the instructions were open: close them.
                    redirectPresenter.close()
                    let (result, finalIntent) = session.finishedResult
                    continuation.resume(returning: .finished(result, finalIntent))
                }
            }
            session.onFinish = { resume(.screenFinished) }
            Task { @MainActor in
                let result = await redirectPresenter.redirect(instructions, authenticationContext: authenticationContext, didOpen: didOpen, didPresent: { safariViewController in
                    session.present(pollingScreen, poll: poll, safariViewController: safariViewController)
                })
                resume(.webView(result))
            }
        }
    }

    private init(host: PollingScreenHosting, intent: ConfirmingIntent) {
        self.host = host
        self.latestIntent = intent
    }

    private func present(_ pollingScreen: ResolvedNextAction.PollingScreen, poll: @escaping () async -> ConfirmingIntent?, safariViewController: SFSafariViewController?) {
        guard let host else { return }
        let viewController = PollingViewController(
            viewModel: PollingViewModel(screen: pollingScreen.screen),
            deadline: pollingScreen.deadline,
            authenticationContext: host,
            poll: { [weak self] completion in
                Task { @MainActor in
                    guard let intent = await poll() else {
                        completion(nil)
                        return
                    }
                    completion(PollingViewController.PollResult(status: intent.pollingStatus, accept: { self?.latestIntent = intent }))
                }
            },
            complete: { [weak self] status in
                self?.finish(status == .succeeded ? .completed : .canceled)
            },
            appearance: host.pollingScreenAppearance,
            safariViewController: safariViewController
        )
        self.viewController = viewController
        host.presentPollingViewController(viewController, safariViewController: safariViewController)
    }

    private var finishedResult: (PaymentSheetResult, ConfirmingIntent?) {
        return (finalResult ?? .canceled, latestIntent)
    }

    private func finish(_ result: PaymentSheetResult) {
        guard finalResult == nil else { return }
        finalResult = result
        let waiters = self.waiters
        self.waiters = []
        waiters.forEach { $0.resume(returning: finishedResult) }
        onFinish?()
        onFinish = nil
    }

    func result() async -> (PaymentSheetResult, ConfirmingIntent?) {
        if finalResult != nil {
            return finishedResult
        }
        return await withCheckedContinuation { waiters.append($0) }
    }

    func stop(dismiss: Bool) {
        onFinish = nil
        guard let viewController else { return }
        viewController.stopPolling()
        let isShowing = viewController.parent != nil || viewController.presentingViewController != nil
        if dismiss, isShowing, let host {
            host.authenticationContextWillDismiss?(viewController)
            host.dismiss(viewController, completion: nil)
        }
    }
}
