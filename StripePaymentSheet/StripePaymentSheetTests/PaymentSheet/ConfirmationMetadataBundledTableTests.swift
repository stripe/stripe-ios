//
//  ConfirmationMetadataBundledTableTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet

/// The bundled `confirmation_metadata.json` must be complete and fully understood, so a bad file fails CI.
final class ConfirmationMetadataBundledTableTests: XCTestCase {
    func testBundledTableDecodesWithoutProblems() {
        // When the bundled file is loaded through the sidecar decoder
        let table = ConfirmationMetadata.loadBundledTable()

        // Then every entry decodes and maps, with no unparsable value, missing field or duplicate
        XCTAssertEqual(table.problems, [])
    }

    @MainActor
    func testBundledTableCoversEveryNativeAndAllowlistedType() {
        let table = ConfirmationMetadata.loadBundledTable()
        // Every type PaymentSheet confirms has an entry, so it can use the engine
        for type in ConfirmationMetadata.nativeTypes {
            XCTAssertNotNil(table.entries[type.identifier], "\(type.identifier) isn't in the bundled table")
        }
        // ...including every type of every routed family
        for family in PaymentConfirmer.routedFamilies {
            XCTAssertFalse(family.types.isEmpty, "\(family) has no types")
            for type in family.types {
                XCTAssertNotNil(table.entries[type.identifier], "\(type.identifier) is routed but isn't in the bundled table")
            }
        }
        // ...and nothing else
        XCTAssertEqual(Set(table.entries.keys), Set(ConfirmationMetadata.nativeTypes.map(\.identifier)))
    }

    func testBadEntriesAreReported() throws {
        // Given a file with one good entry, one with a presenter this SDK doesn't know, and one missing intent_rules
        let good = try JSONSerialization.jsonObject(with: try JSONEncoder().encode(MobileSession.PaymentMethodConfirmation(type: "ideal", confirm: Self.confirm(presenter: "redirect"))))
        let unknownPresenter = try JSONSerialization.jsonObject(with: try JSONEncoder().encode(MobileSession.PaymentMethodConfirmation(type: "eps", confirm: Self.confirm(presenter: "hologram"))))
        var missingRules = try XCTUnwrap(JSONSerialization.jsonObject(with: try JSONEncoder().encode(MobileSession.PaymentMethodConfirmation(type: "fpx", confirm: Self.confirm(presenter: "redirect")))) as? [String: Any])
        missingRules[jsonDict: "confirm"]?["intent_rules"] = nil
        let data = try JSONSerialization.data(withJSONObject: ["payment_method_confirmations": [good, unknownPresenter, missingRules, "not an object"]])

        // When it's decoded
        let table = try ConfirmationMetadata.decodeTable(data)

        // Then the good entry maps, and each bad one is reported
        XCTAssertEqual(Array(table.entries.keys), ["ideal"])
        XCTAssertEqual(table.problems.count, 3, table.problems.joined(separator: "\n"))
        XCTAssertTrue(table.problems.contains { $0.contains("eps") && $0.contains("presenter") })
        // ...intent_rules is required, so that entry doesn't decode at all
        XCTAssertTrue(table.problems.contains { $0.contains("payment_method_confirmations[2]") && $0.contains("intent_rules") })
        XCTAssertTrue(table.problems.contains { $0.contains("payment_method_confirmations[3]") })
    }

    func testClientConstantsAreMergedIntoEntries() throws {
        // Given the bundled table, whose entries are what the server serves (no SDK-internal fields)
        let table = ConfirmationMetadata.loadBundledTable()
        let card = try XCTUnwrap(table.entries["card"])
        let link = try XCTUnwrap(table.entries["link"])
        let usBankAccount = try XCTUnwrap(table.entries["us_bank_account"])
        let alipay = try XCTUnwrap(table.entries["alipay"])

        // Then card and Link go to STPPaymentHandler and cancel the 3DS source
        XCTAssertEqual(card.performer, .stripePaymentHandler)
        XCTAssertEqual(card.onCancel, .cancel3DSSource)
        XCTAssertEqual(link.performer, .stripePaymentHandler)
        XCTAssertEqual(link.onCancel, .cancel3DSSource)
        // ...the native forms' fixed payment_method_options are set
        XCTAssertEqual(card.params.paymentMethodOptions, [.cardCVCRecollection, .cardNetwork])
        XCTAssertEqual(usBankAccount.params.paymentMethodOptions, [.usBankAccountVerificationMethod])
        XCTAssertEqual(link.params.paymentMethodOptions, [])
        // ...card has its closed-web-view rule, for both intent types
        XCTAssertEqual(card.paymentIntent.afterWebViewDismissed, ConfirmationMetadata.StatusRules(processing: .poll(seconds: 30, onTimeout: .succeed), requiresAction: .cancel))
        XCTAssertEqual(card.setupIntent?.afterWebViewDismissed, ConfirmationMetadata.StatusRules(processing: .poll(seconds: 30, onTimeout: .fail), requiresAction: .cancel))
        // ...and every other type gets the defaults, Alipay included (no Marlin ping)
        XCTAssertEqual(alipay.performer, .engine)
        XCTAssertEqual(alipay.onCancel, .none)
        for (type, entry) in table.entries where !["card", "link", "us_bank_account"].contains(type) {
            XCTAssertEqual(entry.performer, .engine, type)
            XCTAssertEqual(entry.onCancel, .none, type)
            XCTAssertEqual(entry.params.paymentMethodOptions, [], type)
            XCTAssertNil(entry.paymentIntent.afterWebViewDismissed, type)
            XCTAssertNil(entry.setupIntent?.afterWebViewDismissed, type)
        }
    }

    func testClientConstantsApplyToAServedEntry() throws {
        // Given a served entry for card, which carries none of the SDK-internal fields
        let confirm = Self.confirm(presenter: "redirect")

        // When it's mapped for card and for iDEAL
        let card = try ConfirmationMetadata(wire: confirm, type: "card")
        let ideal = try ConfirmationMetadata(wire: confirm, type: "ideal")

        // Then card gets its client constants and iDEAL the defaults
        XCTAssertEqual(card.performer, .stripePaymentHandler)
        XCTAssertEqual(card.onCancel, .cancel3DSSource)
        XCTAssertNotNil(card.paymentIntent.afterWebViewDismissed)
        XCTAssertEqual(ideal.performer, .engine)
        XCTAssertEqual(ideal.onCancel, .none)
        XCTAssertNil(ideal.paymentIntent.afterWebViewDismissed)
    }

    func testBundledPollingScreensCarryEnglishStrings() throws {
        // Given the bundled table's polling screens
        let table = ConfirmationMetadata.loadBundledTable()
        for type in PollingViewModel.supportedPaymentMethods {
            let entry = try XCTUnwrap(table.entries[type.identifier])
            let screens = entry.nextActions.values.compactMap { nextAction -> ConfirmationMetadata.NextAction.PollingScreen? in
                if case .pollingScreen(let screen, _) = nextAction.presenter { return screen } else { return nil }
            }
            let screen = try XCTUnwrap(screens.first, type.identifier)
            // Then each has the server's English strings, with the ICU time argument only when it counts down
            XCTAssertEqual(screen.title, "Approve payment", type.identifier)
            XCTAssertEqual(screen.cancelButton, "Cancel and pay another way", type.identifier)
            XCTAssertEqual(screen.failureTitle, "Payment failed", type.identifier)
            XCTAssertEqual(screen.failureInstructions, "Please go back and select another payment method", type.identifier)
            XCTAssertEqual(screen.instructions.contains("{time_remaining}"), screen.showsCountdown, type.identifier)
        }
    }

    func testUnknownNextActionTypeIsKeptAsServed() throws {
        // Given a served entry whose next-action type the SDK has no case for
        let confirm = Self.confirm(presenter: "redirect", nextActionType: "future_redirect")
        // When it's decoded
        let metadata = try ConfirmationMetadata(wire: confirm, type: "ideal")
        // Then the entry is kept under the served type, ready to match the intent's next_action.type
        XCTAssertEqual(Array(metadata.nextActions.keys), ["future_redirect"])
    }

    static func confirm(presenter: String, nextActionType: String = "redirect_to_url") -> MobileSession.PaymentMethodConfirm {
        let rule = MobileSession.StatusRule(outcome: .cancel, pollSeconds: nil, onTimeout: nil)
        let rules = MobileSession.StatusRules(processing: rule, requiresAction: rule)
        let nextAction = MobileSession.NextAction(
            type: nextActionType,
            presenter: MobileSession.NextActionPresenter(rawValue: presenter) ?? .unparsable,
            urlPath: "url",
            browser: .fromNextAction,
            returnUrl: .nextAction,
            appToApp: .universalLinksOnly
        )
        return MobileSession.PaymentMethodConfirm(
            paymentMethodDataType: "ideal",
            nextActions: [nextAction],
            mandateData: .none,
            intentRetrieval: .retrieve,
            intentRules: MobileSession.IntentRulesByKind(paymentIntent: MobileSession.IntentRules(afterConfirm: rules, afterNextAction: rules), setupIntent: nil),
            returnUrl: .optional,
            setup: MobileSession.SetupSupport(supported: false, customerChoiceInPaymentMethodOptions: false)
        )
    }
}
