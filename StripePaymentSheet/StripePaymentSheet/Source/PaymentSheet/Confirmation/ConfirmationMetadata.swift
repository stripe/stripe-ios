//
//  ConfirmationMetadata.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripePayments

/// Everything PaymentSheet needs to confirm one payment method type and finish its payment: the confirm params,
/// the next actions confirmation can return and how to perform each, and what each intent status means after
/// confirmation and after a next action.
///
/// It comes from the server: a served `payment_method_confirmations` entry for a native type, or a server-driven
/// payment method's description. Both are read by `init(wire:type:)`.
///
/// It's a superset of the `mobile_session` contract's `confirm` object: every contract field maps to one field here.
/// The fields marked "Client constant" aren't in the contract: the SDK fixes them per type
/// (`ConfirmationMetadata+ClientConstants.swift`) and merges them into every served entry and description.
struct ConfirmationMetadata: Codable, Equatable {
    var params: Params
    /// Next actions confirmation can return for this type, keyed by the API's `next_action[type]`. Any other next
    /// action, even `redirect_to_url`, fails the payment with `unsupportedAuthenticationErrorCode` and is reported as
    /// an unexpected error: the server vends this table, so a missing next action is fixed there.
    /// Contract: `confirm.next_actions`.
    var nextActions: [String: NextAction]
    var paymentIntent: IntentRules
    /// How to finish a SetupIntent, or nil if PaymentSheet doesn't offer this type for SetupIntents.
    /// Contract: `confirm.intent_rules.setup_intent`.
    var setupIntent: IntentRules?
    /// How to read the intent after a next action. Before one, e.g. polling a `processing` intent right after
    /// confirmation, it's always `retrieve`.
    /// Contract: `confirm.intent_retrieval`.
    var retrieval: Retrieval
    /// What canceling the payment after a next action also does. Client constant.
    var onCancel: CancelSideEffect
    /// Who performs this type's next actions. Client constant.
    var performer: Performer = .engine

    enum Performer: String, Codable, Equatable {
        /// `PaymentConfirmer` performs each next action with the presenter its `NextAction` names.
        case engine
        /// Every next action goes to `STPPaymentHandler.handleNextAction(for:)`, which also owns what happens after it:
        /// card and Link, whose 3DS2, 3DS redirect and post-return rules stay in STPPaymentHandler.
        case stripePaymentHandler
    }

    // MARK: - Params

    /// What goes into the confirm request, beyond the payment method details the form collects.
    struct Params: Codable, Equatable {
        /// `payment_method_data[type]`. Contract: `confirm.payment_method_data_type`.
        var paymentMethodDataType: String
        /// Whether confirming needs a `return_url`. Contract: `confirm.return_url`.
        var returnURL: ReturnURLRequirement
        /// When to send `mandate_data` with inferred online acceptance.
        /// Contract: `confirm.mandate_data` (`online_inferred` is `.always`, `online_inferred_when_setting_up` is `.whenSettingUp`).
        var mandateData: MandateData
        /// Which `setup_future_usage` values this type can be confirmed with, and where PaymentSheet puts them.
        /// Contract: `confirm.setup`.
        var setupFutureUsage: SetupFutureUsage
        /// Fixed `payment_method_options[<type>]` fields PaymentSheet sets for this type. Client constant.
        var paymentMethodOptions: [PaymentMethodOption]

        enum ReturnURLRequirement: String, Codable, Equatable {
            /// Confirmation fails without one. PaymentSheet asserts on a missing `returnURL` for these types.
            case required
            /// Sent when the merchant configured one.
            case sentIfSet
        }

        enum MandateData: String, Codable, Equatable {
            case none
            /// On every confirm.
            case always
            /// Only when the payment method is being set up: a SetupIntent, or a PaymentIntent with
            /// `setup_future_usage` set at the top level or in this type's `payment_method_options`.
            case whenSettingUp
        }

        struct SetupFutureUsage: Codable, Equatable {
            /// Whether the type can be set up: confirmed with `setup_future_usage`, or with a SetupIntent.
            var supportsSetup: Bool

            static let unsupported = SetupFutureUsage(supportsSetup: false)
        }

        enum PaymentMethodOption: String, Codable, Equatable {
            /// Card: `payment_method_options[card][require_cvc_recollection]` and the recollected CVC for saved cards.
            case cardCVCRecollection
            /// Card: `payment_method_options[card][network]` when the customer picks a co-branded network.
            case cardNetwork
            /// US bank account: `payment_method_options[us_bank_account][verification_method]` from the intent.
            case usBankAccountVerificationMethod
        }
    }

    // MARK: - Next actions

    struct NextAction: Codable, Equatable {
        var presenter: Presenter
        /// The field of `next_action[type]` with the URL to open, e.g. `url` or `hosted_voucher_url`.
        /// Contract: `url_path`.
        var urlPath: String?
        /// The field with a web URL to open when `urlPath`'s app isn't installed (Alipay's `url`). Without one, the
        /// web view opens `urlPath`'s URL. Contract: `fallback_url_path`.
        var fallbackURLPath: String?
        /// Which URL STPURLCallbackHandler listens for, i.e. when the customer counts as returned.
        var returnURL: ReturnURLSource
        /// How to try a native app before a web view.
        var appToApp: AppToApp
        /// Replaces the intent's `requires_action` rule while the intent still has this next action after it was
        /// performed. For example, a voucher's `requires_action` means "the customer pays later", so it succeeds.
        /// Contract: `while_requires_action`.
        var whileRequiresAction: Outcome?

        enum Presenter: Codable, Equatable {
            /// Open the next action's URL: as an app first (see `AppToApp`), then in an in-app browser.
            case redirect(browser: Browser)
            /// 3DS2 through Stripe3DS2 (`use_stripe_sdk`), which falls back to a redirect. Stays a special handler.
            case threeDS2
            /// Show `PollingViewController` (BLIK, MB WAY, Bizum), or show it behind the hosted instructions web view
            /// (PayNow, PromptPay, Pix).
            case pollingScreen(PollingScreen, overWebView: Bool)
            /// Nothing to show: the customer finishes later, e.g. verifying microdeposits. The payment succeeds.
            case none
        }

        enum Browser: String, Codable, Equatable {
            /// SFSafariViewController, unless the next action sets `useWebAuthSession`, which uses
            /// ASWebAuthenticationSession with the `stripesdk` callback scheme.
            case fromNextAction
            case safariViewController
        }

        /// The `PollingViewController` config. The strings are localized by the server.
        struct PollingScreen: Codable, Equatable {
            /// How long the screen polls before showing an error, unless `deadlineField` is in the next action.
            var seconds: Int
            var intervalSeconds: Int
            var showsCountdown: Bool
            /// A next action field with the deadline, e.g. Pix's `expires_at`.
            var deadlineField: String?
            var title: String
            /// The instructions under the title. With `showsCountdown`, `{time_remaining}` is replaced with the time left.
            var instructions: String
            var cancelButton: String
            /// The title once the deadline passes without approval.
            var failureTitle: String
            var failureInstructions: String
        }

        enum ReturnURLSource: String, Codable, Equatable {
            /// The next action's own `return_url` (`next_action[type].return_url`).
            case nextAction
            /// The confirm request's `return_url`, which must be set.
            case confirmRequired
            /// The confirm request's `return_url`, if set.
            case confirmIfSet
            /// The confirm request's `return_url` if set, otherwise the next action's (Alipay's next action return
            /// URL is an intermediate trampoline).
            case confirmThenNextAction
            /// Doesn't listen for a return URL; returns on foregrounding or closing the web view.
            case none
        }

        enum AppToApp: String, Codable, Equatable {
            /// Try the URL as an app first. An http(s) URL opens with `universalLinksOnly` (except on Mac Catalyst), so a
            /// missing app falls back to the in-app browser rather than Safari; a custom scheme opens any app.
            case universalLinksOnly
            /// Try the next action's custom-scheme `native_url` first, then open its web `url` in the in-app browser (Alipay).
            case nativeURLThenWeb
            /// Nothing to open.
            case none
        }
    }

    // MARK: - Status rules

    /// What `processing` and `requires_action` mean for one intent type. The other statuses have fixed handling in
    /// `decide`, the same for every payment method.
    struct IntentRules: Codable, Equatable {
        /// Right after confirmation, or when PaymentSheet handles an intent that was confirmed elsewhere.
        var afterConfirm: StatusRules
        /// Each time the intent is read after a next action.
        var afterNextAction: StatusRules
        /// Replaces `afterNextAction` once the customer closes the in-app browser themselves. Client constant (card).
        var afterWebViewDismissed: StatusRules?
    }

    /// Contract: `StatusRules`.
    struct StatusRules: Codable, Equatable {
        var processing: Outcome
        var requiresAction: Outcome
    }

    enum Outcome: Codable, Equatable {
        case succeed
        case fail
        case cancel
        /// Only for `requires_action` right after confirmation.
        case performNextAction
        /// Read the intent every second until its status changes or `seconds` pass, then finish with `onTimeout`.
        /// The first poll sets the deadline for the rest of the payment.
        /// Contract: `outcome: poll` with `poll_seconds` and `on_timeout`.
        case poll(seconds: Int, onTimeout: Terminal)
        /// Don't finish: the next action's screen (PayNow's and PromptPay's polling screen) finishes the payment.
        /// Contract: `wait_for_next_action_screen`.
        case waitForNextActionScreen
    }

    enum Terminal: String, Codable, Equatable {
        case succeed
        case fail
        case cancel
    }

    enum Retrieval: String, Codable, Equatable {
        /// `GET /v1/payment_intents/:id`, expanding `payment_method`.
        case retrieve
        /// `POST /v1/payment_intents/:id/refresh`, which asks the partner for the latest status.
        case refresh
    }

    enum CancelSideEffect: String, Codable, Equatable {
        case none
        /// Cancel the 3DS source (`source_cancel`) of a card or Link payment the customer abandoned in a web view.
        case cancel3DSSource
    }
}

// MARK: - Decisions

extension ConfirmationMetadata {
    enum IntentKind: Equatable {
        case paymentIntent
        case setupIntent
    }

    /// When the intent is being evaluated.
    enum Phase: Equatable {
        /// Right after confirmation, or the first evaluation of an intent confirmed elsewhere.
        case afterConfirm
        /// After a next action, on every read. `webViewDismissed` is whether the customer closed the in-app browser.
        case afterNextAction(webViewDismissed: Bool)
    }

    /// One evaluation of an intent.
    struct Situation: Equatable {
        var intent: IntentKind
        var status: STPPaymentIntentStatus
        /// The intent's `next_action[type]`, if any.
        var nextActionType: String?
        var phase: Phase
        /// Whether a poll's deadline has passed.
        var pollExpired: Bool = false
    }

    enum Decision: Equatable {
        case succeed
        case fail(FailureReason)
        case cancel
        case performNextAction
        case poll(seconds: Int)
        case waitForNextActionScreen
    }

    enum FailureReason: Equatable {
        /// `requires_payment_method`: confirmation failed, e.g. the customer was declined.
        case paymentFailed
        /// `requires_payment_method` when PaymentSheet starts handling a PaymentIntent: STPPaymentHandler treats it
        /// as "no payment method attached" (`requiresPaymentMethodErrorCode`) rather than a decline.
        case requiresPaymentMethod
        /// The rules say this status fails, or the status is unknown.
        case unexpectedStatus
        /// `requires_action` with a next action this type doesn't list.
        case unsupportedNextAction
        /// A SetupIntent for a type with no SetupIntent rules.
        case unsupportedIntent
    }

    static let stripeSDKNextActionType = "use_stripe_sdk"

    /// What the intent's status means for this type. Pure, so the parity harness can compare it with STPPaymentHandler.
    func decide(_ situation: Situation) -> Decision {
        let isAfterNextAction = situation.phase != .afterConfirm
        switch situation.status {
        case .succeeded:
            return .succeed
        case .requiresCapture:
            return situation.intent == .paymentIntent ? .succeed : .fail(.unexpectedStatus)
        case .requiresPaymentMethod:
            return situation.intent == .paymentIntent && !isAfterNextAction ? .fail(.requiresPaymentMethod) : .fail(.paymentFailed)
        case .canceled:
            return .cancel
        case .requiresConfirmation:
            // Manual confirmation: after a next action, the merchant confirms the PaymentIntent on their server.
            return situation.intent == .paymentIntent && isAfterNextAction ? .succeed : .fail(.unexpectedStatus)
        case .unknown:
            return .fail(.unexpectedStatus)
        case .processing, .requiresAction:
            break
        @unknown default:
            return .fail(.unexpectedStatus)
        }

        guard let rules = situation.intent == .paymentIntent ? paymentIntent : setupIntent else {
            return .fail(.unsupportedIntent)
        }
        let statusRules: StatusRules
        switch situation.phase {
        case .afterConfirm:
            statusRules = rules.afterConfirm
        case .afterNextAction(let webViewDismissed):
            statusRules = webViewDismissed ? rules.afterWebViewDismissed ?? rules.afterNextAction : rules.afterNextAction
        }

        var outcome: Outcome
        if situation.status == .processing {
            outcome = statusRules.processing
        } else {
            outcome = statusRules.requiresAction
            if outcome == .performNextAction {
                // `use_stripe_sdk` (3DS2, the intent confirmation challenge) can come for any type, and always goes to
                // STPPaymentHandler.
                guard let type = situation.nextActionType, nextActions[type] != nil || type == Self.stripeSDKNextActionType else {
                    return .fail(.unsupportedNextAction)
                }
            }
            if isAfterNextAction, let type = situation.nextActionType, let override = nextActions[type]?.whileRequiresAction {
                outcome = override
            }
        }

        switch outcome {
        case .succeed:
            return .succeed
        case .fail:
            return .fail(.unexpectedStatus)
        case .cancel:
            return .cancel
        case .performNextAction:
            return .performNextAction
        case .waitForNextActionScreen:
            return .waitForNextActionScreen
        case .poll(let seconds, let onTimeout):
            guard situation.pollExpired || seconds == 0 else {
                return .poll(seconds: seconds)
            }
            switch onTimeout {
            case .succeed: return .succeed
            case .fail: return .fail(.unexpectedStatus)
            case .cancel: return .cancel
            }
        }
    }
}
