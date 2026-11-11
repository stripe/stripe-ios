//
//  ServerDrivenConfirmSpec.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation

/// How `ServerDrivenPaymentHandler` finishes a payment for a server-driven payment method: which next actions it may
/// perform, how it fetches the intent after a next action, and what the non-terminal intent statuses mean.
///
/// It maps 1:1 from the `mobile_session` contract's `confirm.next_actions` and `confirm.post_confirm`.
struct ServerDrivenConfirmSpec: Equatable {
    /// A next action the handler may perform. Any other next action fails the payment.
    enum NextAction: Equatable {
        case redirectToURL
    }

    /// How to fetch the intent after a next action. Before one, e.g. polling a `processing` intent right after
    /// confirmation, the handler always retrieves.
    enum Retrieval: Equatable {
        /// `GET /v1/payment_intents/:id`
        case retrieve
        /// `POST /v1/payment_intents/:id/refresh`, which asks the processor for the latest status.
        case refresh
    }

    /// What a `processing` intent means.
    enum ProcessingOutcome: Equatable {
        case succeed
        case fail
        /// Fetch the intent again every second until its status changes or `pollSeconds` pass, then fail.
        case poll
    }

    /// What a `requires_action` intent means after its next action was performed.
    enum RequiresActionOutcome: Equatable {
        case cancel
        /// Fetch the intent again every second until its status changes or `pollSeconds` pass, then cancel.
        case poll
        case succeed
    }

    let nextActions: [NextAction]
    let retrieval: Retrieval
    /// Applies whenever the intent is `processing`, including right after confirmation.
    let processing: ProcessingOutcome
    /// Applies only after a next action has been performed. Before that, `requires_action` means "perform the next action".
    let requiresAction: RequiresActionOutcome
    /// How long `poll` keeps fetching, starting from the first poll decision. With 0, `poll` doesn't fetch again.
    let pollSeconds: Int
}

extension ServerDrivenConfirmSpec {
    /// The `poll_seconds` range the contract allows.
    static let pollSecondsRange = 0...60

    /// Maps the `mobile_session` confirm fields. Throws `ServerDrivenPaymentMethod.UnsupportedValue` for a value this SDK
    /// can't follow, so the payment method is dropped.
    init(_ confirm: MobileSession.PaymentMethodConfirm) throws {
        typealias UnsupportedValue = ServerDrivenPaymentMethod.UnsupportedValue
        self.nextActions = try confirm.nextActions.map { nextAction in
            guard nextAction.type == "redirect_to_url" else {
                // Any other type, including the native types' next actions (for the native table), which server-driven
                // payment methods can't use yet.
                throw UnsupportedValue(value: "next_action:\(nextAction.type)")
            }
            return .redirectToURL
        }
        let postConfirm = confirm.postConfirm
        switch postConfirm.intentRetrieval {
        case .retrieve:
            self.retrieval = .retrieve
        case .refresh:
            self.retrieval = .refresh
        case .unparsable:
            throw UnsupportedValue(value: "intent_retrieval:unparsable")
        }
        switch postConfirm.onProcessing {
        case .succeed:
            self.processing = .succeed
        case .fail:
            self.processing = .fail
        case .poll:
            self.processing = .poll
        case .unparsable:
            throw UnsupportedValue(value: "on_processing:unparsable")
        }
        switch postConfirm.onRequiresAction {
        case .cancel:
            self.requiresAction = .cancel
        case .poll:
            self.requiresAction = .poll
        case .succeed:
            self.requiresAction = .succeed
        case .unparsable:
            throw UnsupportedValue(value: "on_requires_action:unparsable")
        }
        guard Self.pollSecondsRange.contains(postConfirm.pollSeconds) else {
            throw UnsupportedValue(value: "poll_seconds:\(postConfirm.pollSeconds)")
        }
        self.pollSeconds = postConfirm.pollSeconds
    }
}
