//
//  ServerDrivenConfirmSpec.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation

/// How `ServerDrivenPaymentHandler` finishes a payment for a server-driven payment method: which next actions it may
/// perform, how it fetches the intent after the customer returns, and what the non-terminal intent statuses mean.
///
/// This is the shape the `mobile_session` contract is heading toward. Today's wire fields are booleans
/// (`processing_is_success`, `post_redirect_poll_seconds`) and `init(_:)` adapts them. The intended wire shape is:
/// ```
/// "confirm": {
///   "next_actions": [{"type": "redirect_to_url"}],
///   "post_confirm": {
///     "retrieval": "retrieve" | "refresh",
///     "statuses": {"processing": "succeed" | "fail" | "cancel" | "poll", "requires_action": ...},
///     "poll_seconds": 5
///   }
/// }
/// ```
struct ServerDrivenConfirmSpec: Equatable {
    /// A next action the handler may perform. Any other next action fails the payment.
    enum NextAction: Equatable {
        case redirectToURL
    }

    /// How to fetch the intent after the customer returns.
    enum Retrieval: Equatable {
        /// `GET /v1/payment_intents/:id`
        case retrieve
        /// `POST /v1/payment_intents/:id/refresh`, which asks the processor for the latest status.
        case refresh
    }

    /// What a `processing` or `requires_action` intent means.
    enum Outcome: Equatable {
        case succeed
        case fail
        case cancel
        /// Fetch the intent again every second for up to `pollSeconds`. If it's still in this status after that,
        /// a `processing` intent fails and a `requires_action` intent is canceled, like `STPPaymentHandler`.
        case poll
    }

    let nextActions: [NextAction]
    let retrieval: Retrieval
    /// Applies whenever the intent is `processing`, including right after confirmation.
    let processing: Outcome
    /// Applies only after a next action has been performed. Before that, `requires_action` means "perform the next action".
    let requiresAction: Outcome
    /// How long `poll` keeps fetching, starting from the first fetch. 0 fetches once.
    let pollSeconds: Int
}

extension ServerDrivenConfirmSpec {
    /// Adapts today's `mobile_session` confirm fields.
    /// - `processing_is_success: true` is `processing: succeed`. `false` polls, like `STPPaymentHandler` does for a type
    ///   whose `processing` isn't success, but for `post_redirect_poll_seconds` rather than a hardcoded 30s.
    /// - `post_redirect_poll_seconds > 0` is `requires_action: poll`, and 0 is `requires_action: cancel`.
    /// - There's no wire field for retrieval yet, so it's always `retrieve`.
    init(_ confirm: MobileSession.PaymentMethodConfirm) throws {
        self.nextActions = try confirm.nextActions.map { nextAction in
            switch nextAction {
            case .redirectToUrl:
                return .redirectToURL
            case .unparsable:
                throw ServerDrivenPaymentMethod.UnsupportedValue(value: "next_action:unparsable")
            }
        }
        self.retrieval = .retrieve
        self.processing = confirm.processingIsSuccess ? .succeed : .poll
        self.requiresAction = confirm.postRedirectPollSeconds > 0 ? .poll : .cancel
        self.pollSeconds = max(0, confirm.postRedirectPollSeconds)
    }
}
