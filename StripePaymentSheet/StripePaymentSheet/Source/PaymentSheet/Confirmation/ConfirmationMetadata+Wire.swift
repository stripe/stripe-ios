//
//  ConfirmationMetadata+Wire.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// `ConfirmationMetadata` from the `mobile_session` wire shape: an entry of `payment_method_confirmations`, whose
/// `confirm` is the contract's `PaymentMethodConfirm`, merged with the SDK's client constants for its type.
extension ConfirmationMetadata {
    /// A field the table needs is missing or has a value this SDK can't follow.
    struct WireError: Error, Equatable, CustomStringConvertible {
        let field: String
        var description: String { "confirm.\(field)" }
    }

    /// The same mapping reads a served entry and a server-driven payment method's description. An entry that can't
    /// describe the whole policy throws, so a type never runs half described. `type` picks the client constants.
    init(wire confirm: MobileSession.PaymentMethodConfirm, type: String) throws {
        let intentRules = confirm.intentRules
        let setup = confirm.setup
        let returnURL: Params.ReturnURLRequirement
        switch confirm.returnUrl {
        case .required: returnURL = .required
        case .optional: returnURL = .sentIfSet
        case .unparsable: throw WireError(field: "return_url")
        }
        let mandateData: Params.MandateData
        switch confirm.mandateData {
        case .none: mandateData = .none
        case .onlineInferred: mandateData = .always
        case .onlineInferredWhenSettingUp: mandateData = .whenSettingUp
        case .unparsable: throw WireError(field: "mandate_data")
        }
        var nextActions: [String: NextAction] = [:]
        for nextAction in confirm.nextActions {
            nextActions[nextAction.type] = try NextAction(wire: nextAction)
        }
        let retrieval: Retrieval
        switch confirm.intentRetrieval {
        case .retrieve: retrieval = .retrieve
        case .refresh: retrieval = .refresh
        case .unparsable: throw WireError(field: "intent_retrieval")
        }
        self.init(
            params: Params(
                paymentMethodDataType: confirm.paymentMethodDataType,
                returnURL: returnURL,
                mandateData: mandateData,
                setupFutureUsage: Params.SetupFutureUsage(supportsSetup: setup.supported, sendsCustomerChoiceInPaymentMethodOptions: setup.customerChoiceInPaymentMethodOptions),
                paymentMethodOptions: []
            ),
            nextActions: nextActions,
            paymentIntent: try IntentRules(wire: intentRules.paymentIntent, field: "intent_rules.payment_intent"),
            setupIntent: try intentRules.setupIntent.map { try IntentRules(wire: $0, field: "intent_rules.setup_intent") },
            retrieval: retrieval,
            onCancel: .none
        )
        apply(Self.clientConstants(for: type))
    }
}

extension ConfirmationMetadata.NextAction {
    init(wire nextAction: MobileSession.NextAction) throws {
        typealias WireError = ConfirmationMetadata.WireError
        let field = "next_actions[\(nextAction.type)]"
        let presenter: Presenter
        switch nextAction.presenter {
        case .redirect:
            switch nextAction.browser {
            case .fromNextAction: presenter = .redirect(browser: .fromNextAction)
            case .safariViewController: presenter = .redirect(browser: .safariViewController)
            case .unparsable, nil: throw WireError(field: "\(field).browser")
            }
        case .threeDs2:
            presenter = .threeDS2
        case .pollingScreen:
            guard let screen = nextAction.pollingScreen else { throw WireError(field: "\(field).polling_screen") }
            presenter = .pollingScreen(
                PollingScreen(
                    seconds: screen.seconds,
                    intervalSeconds: screen.intervalSeconds,
                    showsCountdown: screen.showsCountdown,
                    deadlineField: screen.deadlineField,
                    title: screen.title,
                    instructions: screen.instructions,
                    cancelButton: screen.cancelButton,
                    failureTitle: screen.failureTitle,
                    failureInstructions: screen.failureInstructions
                ),
                overWebView: screen.overWebView
            )
        case .none:
            presenter = .none
        case .unparsable:
            throw WireError(field: "\(field).presenter")
        }
        let returnURL: ReturnURLSource
        switch nextAction.returnUrl {
        case .nextAction: returnURL = .nextAction
        case .confirmRequired: returnURL = .confirmRequired
        case .confirmIfSet: returnURL = .confirmIfSet
        case .confirmThenNextAction: returnURL = .confirmThenNextAction
        case .none: returnURL = .none
        case .unparsable: throw WireError(field: "\(field).return_url")
        }
        let appToApp: AppToApp
        switch nextAction.appToApp {
        case .universalLinksOnly: appToApp = .universalLinksOnly
        case .nativeUrlThenWeb: appToApp = .nativeURLThenWeb
        case .none: appToApp = .none
        case .unparsable: throw WireError(field: "\(field).app_to_app")
        }
        self.init(
            presenter: presenter,
            urlPath: nextAction.urlPath,
            fallbackURLPath: nextAction.fallbackUrlPath,
            returnURL: returnURL,
            appToApp: appToApp,
            whileRequiresAction: try nextAction.whileRequiresAction.map { try ConfirmationMetadata.Outcome(wire: $0, field: "\(field).while_requires_action") }
        )
    }
}

extension ConfirmationMetadata.IntentRules {
    init(wire rules: MobileSession.IntentRules, field: String) throws {
        self.init(
            afterConfirm: try ConfirmationMetadata.StatusRules(wire: rules.afterConfirm, field: "\(field).after_confirm"),
            afterNextAction: try ConfirmationMetadata.StatusRules(wire: rules.afterNextAction, field: "\(field).after_next_action"),
            afterWebViewDismissed: nil
        )
    }
}

extension ConfirmationMetadata.StatusRules {
    init(wire rules: MobileSession.StatusRules, field: String) throws {
        self.init(
            processing: try ConfirmationMetadata.Outcome(wire: rules.processing, field: "\(field).processing"),
            requiresAction: try ConfirmationMetadata.Outcome(wire: rules.requiresAction, field: "\(field).requires_action")
        )
    }
}

extension ConfirmationMetadata.Outcome {
    init(wire rule: MobileSession.StatusRule, field: String) throws {
        switch rule.outcome {
        case .succeed: self = .succeed
        case .fail: self = .fail
        case .cancel: self = .cancel
        case .performNextAction: self = .performNextAction
        case .waitForNextActionScreen: self = .waitForNextActionScreen
        case .poll:
            guard let seconds = rule.pollSeconds, seconds >= 0 else {
                throw ConfirmationMetadata.WireError(field: "\(field).poll_seconds")
            }
            switch rule.onTimeout {
            case .succeed: self = .poll(seconds: seconds, onTimeout: .succeed)
            case .fail: self = .poll(seconds: seconds, onTimeout: .fail)
            case .cancel: self = .poll(seconds: seconds, onTimeout: .cancel)
            case .unparsable, nil: throw ConfirmationMetadata.WireError(field: "\(field).on_timeout")
            }
        case .unparsable:
            throw ConfirmationMetadata.WireError(field: "\(field).outcome")
        }
    }
}

// MARK: - Served entries

extension ConfirmationMetadata {
    /// Maps a session's `payment_method_confirmations`, keyed by type. An entry this SDK can't follow, or a repeated
    /// type, is left out and passed to `onProblem`, so that type is confirmed with STPPaymentHandler. Entries that didn't
    /// decode were already dropped and reported by `MobileSession.decodeSidecar`.
    static func servedEntries(
        _ confirmations: [MobileSession.PaymentMethodConfirmation],
        onProblem: (_ type: String, _ value: String) -> Void = reportServedEntryProblem
    ) -> [String: ConfirmationMetadata] {
        var entries: [String: ConfirmationMetadata] = [:]
        for entry in confirmations {
            guard entries[entry.type] == nil else {
                onProblem(entry.type, "duplicate_type")
                continue
            }
            do {
                entries[entry.type] = try ConfirmationMetadata(wire: entry.confirm, type: entry.type)
            } catch {
                onProblem(entry.type, (error as? WireError)?.description ?? "\(error)")
            }
        }
        return entries
    }

    /// The server should only send entries this SDK version can follow, so a problem means its capability table is wrong.
    static func reportServedEntryProblem(type: String, value: String) {
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(
            event: .paymentSheetMobileSessionPaymentMethodDropped,
            params: [
                "payment_method_type": type,
                "key": "payment_method_confirmations",
                "reason": "unsupported_value",
                "unsupported_value": value,
            ]
        )
    }
}
