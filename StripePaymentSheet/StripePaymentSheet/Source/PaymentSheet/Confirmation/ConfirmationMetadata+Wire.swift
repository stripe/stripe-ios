//
//  ConfirmationMetadata+Wire.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation

/// `ConfirmationMetadata` from the `mobile_session` wire shape: an entry of `payment_method_confirmations`, whose
/// `confirm` is the contract's `PaymentMethodConfirm` plus the fields pending in mint (`MobileSession.swift`, "PENDING MINT").
extension ConfirmationMetadata {
    /// A field the table needs is missing or has a value this SDK can't follow.
    struct WireError: Error, Equatable, CustomStringConvertible {
        let field: String
        var description: String { "confirm.\(field)" }
    }

    /// Every field is required here, unlike for a server-driven payment method's v1 `confirm`: an entry that can't
    /// describe the whole policy throws, so a type never runs half described.
    init(wire confirm: MobileSession.PaymentMethodConfirm) throws {
        guard let intentRules = confirm.intentRules else { throw WireError(field: "intent_rules") }
        guard let setup = confirm.setup else { throw WireError(field: "setup") }
        let returnURL: Params.ReturnURLRequirement
        switch confirm.returnUrl {
        case .required: returnURL = .required
        case .optional: returnURL = .sentIfSet
        case .unparsable, nil: throw WireError(field: "return_url")
        }
        let mandateData: Params.MandateData
        switch confirm.mandateData {
        case .none: mandateData = .none
        case .onlineInferred: mandateData = .always
        case .onlineInferredWhenSettingUp: mandateData = .whenSettingUp
        case .unparsable: throw WireError(field: "mandate_data")
        }
        let paymentMethodOptions: [Params.PaymentMethodOption] = try (confirm.paymentMethodOptions ?? []).map {
            switch $0 {
            case .cardCvcRecollection: return .cardCVCRecollection
            case .cardNetwork: return .cardNetwork
            case .usBankAccountVerificationMethod: return .usBankAccountVerificationMethod
            case .unparsable: throw WireError(field: "payment_method_options")
            }
        }
        var nextActions: [String: NextAction] = [:]
        for nextAction in confirm.nextActions {
            guard nextAction.type != .unparsable else { throw WireError(field: "next_actions.type") }
            nextActions[nextAction.type.rawValue] = try NextAction(wire: nextAction)
        }
        let retrieval: Retrieval
        switch confirm.postConfirm.intentRetrieval {
        case .retrieve: retrieval = .retrieve
        case .refresh: retrieval = .refresh
        case .unparsable: throw WireError(field: "post_confirm.intent_retrieval")
        }
        let beforeFetch: BeforeFetch?
        switch confirm.beforeFetch {
        case .loadAlipayMarlinReturnUrl: beforeFetch = .loadAlipayMarlinReturnURL
        case nil: beforeFetch = nil
        case .unparsable: throw WireError(field: "before_fetch")
        }
        let onCancel: CancelSideEffect
        switch confirm.onCancel {
        case .some(.none): onCancel = .none
        case .cancel3dsSource: onCancel = .cancel3DSSource
        case .unparsable, nil: throw WireError(field: "on_cancel")
        }
        let performer: Performer
        switch confirm.performer {
        case .engine: performer = .engine
        case .stripePaymentHandler: performer = .stripePaymentHandler
        case .unparsable, nil: throw WireError(field: "performer")
        }
        self.init(
            params: Params(
                paymentMethodDataType: confirm.paymentMethodDataType,
                returnURL: returnURL,
                mandateData: mandateData,
                setupFutureUsage: Params.SetupFutureUsage(supportsSetup: setup.supported, sendsCustomerChoiceInPaymentMethodOptions: setup.customerChoiceInPaymentMethodOptions),
                paymentMethodOptions: paymentMethodOptions
            ),
            nextActions: nextActions,
            paymentIntent: try IntentRules(wire: intentRules.paymentIntent, field: "intent_rules.payment_intent"),
            setupIntent: try intentRules.setupIntent.map { try IntentRules(wire: $0, field: "intent_rules.setup_intent") },
            retrieval: retrieval,
            beforeFetch: beforeFetch,
            onCancel: onCancel,
            performer: performer
        )
    }
}

extension ConfirmationMetadata.NextAction {
    init(wire nextAction: MobileSession.NextAction) throws {
        typealias WireError = ConfirmationMetadata.WireError
        let field = "next_actions[\(nextAction.type.rawValue)]"
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
            let instructions: PollingScreen.Instructions
            switch screen.instructions {
            case .blik: instructions = .blik
            case .paynow: instructions = .paynow
            case .mbWay: instructions = .mbWay
            case .bizum: instructions = .bizum
            case .pix: instructions = .pix
            case .unparsable: throw WireError(field: "\(field).polling_screen.instructions")
            }
            presenter = .pollingScreen(
                PollingScreen(seconds: screen.seconds, intervalSeconds: screen.intervalSeconds, showsCountdown: screen.showsCountdown, deadlineField: screen.deadlineField, instructions: instructions),
                overWebView: screen.overWebView
            )
        case .some(.none):
            presenter = .none
        case .unparsable, nil:
            throw WireError(field: "\(field).presenter")
        }
        let returnURL: ReturnURLSource
        switch nextAction.returnUrl {
        case .nextAction: returnURL = .nextAction
        case .confirmRequired: returnURL = .confirmRequired
        case .confirmIfSet: returnURL = .confirmIfSet
        case .confirmThenNextAction: returnURL = .confirmThenNextAction
        case .some(.none): returnURL = .none
        case .unparsable, nil: throw WireError(field: "\(field).return_url")
        }
        let appToApp: AppToApp
        switch nextAction.appToApp {
        case .universalLinksOnly: appToApp = .universalLinksOnly
        case .nativeUrlThenWeb: appToApp = .nativeURLThenWeb
        case .some(.none): appToApp = .none
        case .unparsable, nil: throw WireError(field: "\(field).app_to_app")
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
            afterWebViewDismissed: try rules.afterWebViewDismissed.map { try ConfirmationMetadata.StatusRules(wire: $0, field: "\(field).after_web_view_dismissed") }
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

// MARK: - The bundled table

extension ConfirmationMetadata {
    /// `Resources/JSON/confirmation_metadata.json`: a `mobile_session` sidecar with only `payment_method_confirmations`,
    /// a stand-in until the server sends it.
    static let bundledTableResourceName = "confirmation_metadata"

    struct Table {
        var entries: [String: ConfirmationMetadata] = [:]
        /// Entries that didn't decode or map, and duplicates. A bundled file with any is a bug.
        var problems: [String] = []
    }

    /// Decodes a sidecar's `payment_method_confirmations` the way the sidecar itself is decoded (`MobileSession.decode`).
    static func decodeTable(_ data: Data) throws -> Table {
        var table = Table()
        let session = try MobileSession.decode(data) { dropped in
            table.problems.append("\(dropped.key)[\(dropped.index)] didn't decode: \(dropped.error)")
        }
        for entry in session.paymentMethodConfirmations ?? [] {
            guard table.entries[entry.type] == nil else {
                table.problems.append("\(entry.type) is listed twice")
                continue
            }
            do {
                table.entries[entry.type] = try ConfirmationMetadata(wire: entry.confirm)
            } catch {
                table.problems.append("\(entry.type): \(error)")
            }
        }
        return table
    }

    static func loadBundledTable() -> Table {
        guard
            let url = StripePaymentSheetBundleLocator.resourcesBundle.url(forResource: bundledTableResourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            return Table(problems: ["\(bundledTableResourceName).json isn't in the bundle"])
        }
        do {
            return try decodeTable(data)
        } catch {
            return Table(problems: ["\(bundledTableResourceName).json didn't decode: \(error)"])
        }
    }
}
