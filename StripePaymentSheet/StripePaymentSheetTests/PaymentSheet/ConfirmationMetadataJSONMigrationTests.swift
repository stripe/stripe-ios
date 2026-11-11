//
//  ConfirmationMetadataJSONMigrationTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePayments

/// One-off: proves the bundled `confirmation_metadata.json` holds exactly the Swift default table, before the Swift table
/// is deleted. It encodes each Swift entry to the wire shape, and (re)writes the file when it differs.
final class ConfirmationMetadataJSONMigrationTests: XCTestCase {
    func testBundledJSONHoldsTheSwiftTable() throws {
        // Given today's Swift table, encoded to the wire shape
        let swiftTable = Dictionary(uniqueKeysWithValues: ConfirmationMetadata.nativeTypes.map { ($0.identifier, ConfirmationMetadata.native(for: $0)!) })
        let session = MobileSession.Session(
            paymentMethodAvailability: nil,
            paymentMethods: nil,
            logMessages: nil,
            paymentMethodConfirmations: ConfirmationMetadata.nativeTypes.map { MobileSession.PaymentMethodConfirmation(type: $0.identifier, confirm: swiftTable[$0.identifier]!.wire) }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let expected = try encoder.encode(session)

        // ...which decodes back to the same table through the sidecar decoder
        let roundTripped = try ConfirmationMetadata.decodeTable(expected)
        XCTAssertEqual(roundTripped.problems, [])
        XCTAssertEqual(roundTripped.entries, swiftTable)

        // When the bundled file is read
        let bundled = ConfirmationMetadata.loadBundledTable()

        // Then it's the same table
        if bundled.entries != swiftTable || !bundled.problems.isEmpty {
            let path = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("StripePaymentSheet/Resources/JSON/confirmation_metadata.json")
            try (expected + Data("\n".utf8)).write(to: path)
            XCTFail("Rewrote \(path.path) from the Swift table; rebuild and run again")
        }
    }
}

// MARK: - Swift table → wire

extension ConfirmationMetadata {
    var wire: MobileSession.PaymentMethodConfirm {
        let retrieval: MobileSession.IntentRetrieval = retrieval == .refresh ? .refresh : .retrieve
        return MobileSession.PaymentMethodConfirm(
            paymentMethodDataType: params.paymentMethodDataType,
            nextActions: nextActions.keys.sorted().map { nextActions[$0]!.wire(type: $0) },
            mandateData: {
                switch params.mandateData {
                case .none: return .none
                case .always: return .onlineInferred
                case .whenSettingUp: return .onlineInferredWhenSettingUp
                }
            }(),
            setupFutureUsage: .none,
            postConfirm: coarsePostConfirm(retrieval: retrieval),
            intentRules: MobileSession.IntentRulesByKind(paymentIntent: paymentIntent.wire, setupIntent: setupIntent?.wire),
            returnUrl: params.returnURL == .required ? .required : .optional,
            setup: MobileSession.SetupSupport(supported: params.setupFutureUsage.supportsSetup, customerChoiceInPaymentMethodOptions: params.setupFutureUsage.sendsCustomerChoiceInPaymentMethodOptions),
            paymentMethodOptions: params.paymentMethodOptions.isEmpty ? nil : params.paymentMethodOptions.map {
                switch $0 {
                case .cardCVCRecollection: return .cardCvcRecollection
                case .cardNetwork: return .cardNetwork
                case .usBankAccountVerificationMethod: return .usBankAccountVerificationMethod
                }
            },
            beforeFetch: beforeFetch.map { _ in .loadAlipayMarlinReturnUrl },
            onCancel: onCancel == .cancel3DSSource ? .cancel3dsSource : MobileSession.CancelSideEffect.none,
            performer: performer == .stripePaymentHandler ? .stripePaymentHandler : .engine
        )
    }

    /// v1's `post_confirm`, for SDKs that don't read `intent_rules`: the PaymentIntent's after-next-action rules, as close as
    /// v1 can say them. This SDK ignores everything but `intent_retrieval` when `intent_rules` is present.
    func coarsePostConfirm(retrieval: MobileSession.IntentRetrieval) -> MobileSession.PostConfirm {
        let rules = paymentIntent.afterNextAction
        var pollSeconds = 0
        let onProcessing: MobileSession.OnProcessing
        switch rules.processing {
        case .succeed: onProcessing = .succeed
        case .poll(let seconds, _): onProcessing = .poll; pollSeconds = seconds
        default: onProcessing = .fail
        }
        let onRequiresAction: MobileSession.OnRequiresAction
        switch rules.requiresAction {
        case .succeed: onRequiresAction = .succeed
        case .poll(let seconds, _): onRequiresAction = .poll; pollSeconds = pollSeconds == 0 ? seconds : pollSeconds
        default: onRequiresAction = .cancel
        }
        return MobileSession.PostConfirm(intentRetrieval: retrieval, onProcessing: onProcessing, onRequiresAction: onRequiresAction, pollSeconds: min(pollSeconds, 60))
    }
}

extension ConfirmationMetadata.NextAction {
    func wire(type: String) -> MobileSession.NextAction {
        var nextAction = MobileSession.NextAction(type: MobileSession.NextActionType(rawValue: type)!)
        switch presenter {
        case .redirect(let browser):
            nextAction.presenter = .redirect
            nextAction.browser = browser == .fromNextAction ? .fromNextAction : .safariViewController
        case .threeDS2:
            nextAction.presenter = .threeDs2
        case .pollingScreen(let screen, let overWebView):
            nextAction.presenter = .pollingScreen
            let instructions: MobileSession.PollingInstructions = {
                switch screen.instructions {
                case .blik: return .blik
                case .paynow: return .paynow
                case .mbWay: return .mbWay
                case .bizum: return .bizum
                case .pix: return .pix
                }
            }()
            nextAction.pollingScreen = MobileSession.PollingScreen(seconds: screen.seconds, intervalSeconds: screen.intervalSeconds, showsCountdown: screen.showsCountdown, deadlineField: screen.deadlineField, instructions: instructions, overWebView: overWebView)
        case .none:
            nextAction.presenter = MobileSession.NextActionPresenter.none
        }
        nextAction.urlPath = urlPath
        nextAction.fallbackUrlPath = fallbackURLPath
        nextAction.returnUrl = {
            switch returnURL {
            case .nextAction: return .nextAction
            case .confirmRequired: return .confirmRequired
            case .confirmIfSet: return .confirmIfSet
            case .confirmThenNextAction: return .confirmThenNextAction
            case .none: return MobileSession.NextActionReturnURL.none
            }
        }()
        nextAction.appToApp = {
            switch appToApp {
            case .universalLinksOnly: return .universalLinksOnly
            case .nativeURLThenWeb: return .nativeUrlThenWeb
            case .none: return MobileSession.NextActionAppToApp.none
            }
        }()
        nextAction.whileRequiresAction = whileRequiresAction?.wire
        return nextAction
    }
}

extension ConfirmationMetadata.IntentRules {
    var wire: MobileSession.IntentRules {
        return MobileSession.IntentRules(afterConfirm: afterConfirm.wire, afterNextAction: afterNextAction.wire, afterWebViewDismissed: afterWebViewDismissed?.wire)
    }
}

extension ConfirmationMetadata.StatusRules {
    var wire: MobileSession.StatusRules {
        return MobileSession.StatusRules(processing: processing.wire, requiresAction: requiresAction.wire)
    }
}

extension ConfirmationMetadata.Outcome {
    var wire: MobileSession.StatusRule {
        switch self {
        case .succeed: return .init(outcome: .succeed, pollSeconds: nil, onTimeout: nil)
        case .fail: return .init(outcome: .fail, pollSeconds: nil, onTimeout: nil)
        case .cancel: return .init(outcome: .cancel, pollSeconds: nil, onTimeout: nil)
        case .performNextAction: return .init(outcome: .performNextAction, pollSeconds: nil, onTimeout: nil)
        case .waitForNextActionScreen: return .init(outcome: .waitForNextActionScreen, pollSeconds: nil, onTimeout: nil)
        case .poll(let seconds, let onTimeout):
            let timeout: MobileSession.PollTimeoutOutcome = {
                switch onTimeout {
                case .succeed: return .succeed
                case .fail: return .fail
                case .cancel: return .cancel
                }
            }()
            return .init(outcome: .poll, pollSeconds: seconds, onTimeout: timeout)
        }
    }
}
