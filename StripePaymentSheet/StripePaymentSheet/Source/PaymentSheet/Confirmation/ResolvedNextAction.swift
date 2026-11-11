//
//  ResolvedNextAction.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripePayments

/// An intent's next action, resolved against its `ConfirmationMetadata`: which primitive performs it, with every URL
/// already read out of `next_action[type]`. Resolving is pure, so the parity harness compares it with STPPaymentHandler's
/// dispatch directly.
enum ResolvedNextAction: Equatable {
    /// Open a URL in another app or a web view, then wait for the customer to come back.
    case redirect(Redirect)
    /// Show the polling screen, optionally behind a web view, and let it finish the payment.
    case pollingScreen(PollingScreen)
    /// Nothing to show (microdeposits): the next action counts as performed.
    case none
    /// `STPPaymentHandler.handleNextAction(for:)` performs it and finishes the payment.
    case stripeSDK

    struct Redirect: Equatable {
        /// Tried as an app first. An http(s) URL opens only as a universal link (except on Mac Catalyst), so a missing
        /// app falls back to `webURL` rather than Safari. Nil goes straight to the web view.
        var appURL: URL?
        /// Opened in the in-app browser when the app doesn't open. A non-web URL fails with `requiredAppNotAvailable`.
        var webURL: URL?
        /// The URL that means the customer is back, registered with STPURLCallbackHandler.
        var returnURL: URL?
        /// ASWebAuthenticationSession instead of SFSafariViewController.
        var useWebAuthSession: Bool
        /// Follow one HTTP redirect first, so ASWebAuthenticationSession's consent dialog shows the PM's domain.
        var followRedirects: Bool
    }

    struct PollingScreen: Equatable {
        var screen: ConfirmationMetadata.NextAction.PollingScreen
        /// The next action's own deadline (Pix's `expires_at`), which replaces `screen.seconds`.
        var deadline: Date?
        /// The hosted instructions to show in front of the screen (PayNow, PromptPay, Pix).
        var instructions: Redirect?
    }

    /// The `presenter` analytics value.
    var analyticsName: String {
        switch self {
        case .redirect: return "redirect"
        case .pollingScreen: return "polling_screen"
        case .none: return "none"
        case .stripeSDK: return "stripe_sdk"
        }
    }

    /// - Parameter confirmReturnURL: The confirm request's `return_url`.
    /// - Throws: STPPaymentHandler's error for a next action that's missing, unsupported, or missing details or a return URL.
    init(intent: ConfirmingIntent, metadata: ConfirmationMetadata, confirmReturnURL: String?) throws {
        guard let type = intent.nextActionType else {
            throw PaymentConfirmer.error(.unexpectedErrorCode, loggingSafeErrorMessage: "Performing a next action without one")
        }
        // 3DS2, the 3DS redirect and the intent confirmation challenge, for any type; and every next action of card and Link.
        if type == ConfirmationMetadata.stripeSDKNextActionType || metadata.performer == .stripePaymentHandler {
            self = .stripeSDK
            return
        }
        guard let nextAction = metadata.nextActions[type] else {
            throw PaymentConfirmer.error(.unsupportedAuthenticationErrorCode, loggingSafeErrorMessage: "Unsupported next action \(type)")
        }
        let details = intent.nextAction?.allResponseFields[type] as? [AnyHashable: Any] ?? [:]
        switch nextAction.presenter {
        case .threeDS2:
            self = .stripeSDK
        case .none:
            self = .none
        case .redirect(let browser):
            self = .redirect(try Self.redirect(nextAction, browser: browser, type: type, details: details, confirmReturnURL: confirmReturnURL))
        case .pollingScreen(let screen, let overWebView):
            let deadline = screen.deadlineField
                .flatMap { details[$0] as? NSNumber }
                .map { Date(timeIntervalSince1970: $0.doubleValue) }
            let instructions = overWebView
                ? try Self.redirect(nextAction, browser: .safariViewController, type: type, details: details, confirmReturnURL: confirmReturnURL)
                : nil
            self = .pollingScreen(PollingScreen(screen: screen, deadline: deadline, instructions: instructions))
        }
    }

    private static func redirect(
        _ nextAction: ConfirmationMetadata.NextAction,
        browser: ConfirmationMetadata.NextAction.Browser,
        type: String,
        details: [AnyHashable: Any],
        confirmReturnURL: String?
    ) throws -> Redirect {
        let missingDetails = PaymentConfirmer.error(.unexpectedErrorCode, loggingSafeErrorMessage: "Authentication action \(type) is missing expected details.")
        let url = nextAction.urlPath.flatMap { details[$0] as? String }.flatMap(URL.init(string:))
        let fallbackURL = nextAction.fallbackURLPath.flatMap { details[$0] as? String }.flatMap(URL.init(string:))
        // Alipay's `native_url` is optional; without it, STPPaymentHandler opens the web `url`.
        guard let primaryURL = url ?? fallbackURL else {
            throw missingDetails
        }

        let confirmURL = confirmReturnURL.flatMap(URL.init(string:))
        let nextActionURL = (details["return_url"] as? String).flatMap(URL.init(string:))
        let returnURL: URL?
        switch nextAction.returnURL {
        case .nextAction:
            returnURL = nextActionURL
        case .confirmRequired:
            guard let confirmURL else {
                // STPPaymentHandler also asserts here (SPH:1456); PaymentSheet only offers these types with a returnURL.
                throw PaymentConfirmer.error(.missingReturnURL)
            }
            returnURL = confirmURL
        case .confirmIfSet:
            returnURL = confirmURL
        case .confirmThenNextAction:
            returnURL = confirmURL ?? nextActionURL
        case .none:
            returnURL = nil
        }

        let appURL: URL?
        let webURL: URL?
        switch nextAction.appToApp {
        case .universalLinksOnly:
            appURL = url
            webURL = fallbackURL ?? url
        case .nativeURLThenWeb:
            appURL = url
            webURL = fallbackURL
        case .none:
            appURL = nil
            webURL = fallbackURL ?? url
        }

        let flags = browser == .fromNextAction
        return Redirect(
            appURL: appURL,
            webURL: webURL,
            returnURL: returnURL,
            useWebAuthSession: flags && Self.stripeFlag("useWebAuthSession", in: primaryURL),
            followRedirects: flags && Self.stripeFlag("followRedirectsInSDK", in: primaryURL)
        )
    }

    /// Whether a stripe.com URL sets an internal flag, like `STPIntentActionRedirectToURL.stripeFlagValue`.
    static func stripeFlag(_ name: String, in url: URL) -> Bool {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let host = components.host,
            host.hasSuffix("stripe.com"),
            let item = components.queryItems?.first(where: { $0.name == name })
        else {
            return false
        }
        return item.value == "true"
    }
}
