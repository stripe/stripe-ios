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
        XCTAssertTrue(table.problems.contains { $0.contains("fpx") && $0.contains("intent_rules") })
        XCTAssertTrue(table.problems.contains { $0.contains("payment_method_confirmations[3]") })
    }

    static func confirm(presenter: String) -> MobileSession.PaymentMethodConfirm {
        let rule = MobileSession.StatusRule(outcome: .cancel, pollSeconds: nil, onTimeout: nil)
        let rules = MobileSession.StatusRules(processing: rule, requiresAction: rule)
        var nextAction = MobileSession.NextAction(type: .redirectToUrl)
        nextAction.presenter = MobileSession.NextActionPresenter(rawValue: presenter) ?? .unparsable
        nextAction.browser = .fromNextAction
        nextAction.urlPath = "url"
        nextAction.returnUrl = .nextAction
        nextAction.appToApp = .universalLinksOnly
        return MobileSession.PaymentMethodConfirm(
            paymentMethodDataType: "ideal",
            nextActions: [nextAction],
            mandateData: .none,
            setupFutureUsage: .none,
            postConfirm: MobileSession.PostConfirm(intentRetrieval: .retrieve, onProcessing: .fail, onRequiresAction: .cancel, pollSeconds: 0),
            intentRules: MobileSession.IntentRulesByKind(paymentIntent: MobileSession.IntentRules(afterConfirm: rules, afterNextAction: rules, afterWebViewDismissed: nil), setupIntent: nil),
            returnUrl: .optional,
            setup: MobileSession.SetupSupport(supported: false, customerChoiceInPaymentMethodOptions: false),
            paymentMethodOptions: nil,
            beforeFetch: nil,
            onCancel: MobileSession.CancelSideEffect.none,
            performer: .engine
        )
    }
}
