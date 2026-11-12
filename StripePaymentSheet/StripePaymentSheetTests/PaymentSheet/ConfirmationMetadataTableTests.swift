//
//  ConfirmationMetadataTableTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet

// MARK: - The table fixture

/// `Resources/payment_method_confirmations.json`: mint's confirmation table, the `payment_method_confirmations` the
/// server sends, in the `mobile_session` wire shape. The SDK doesn't bundle it; the parity harnesses and tests read it.
extension ConfirmationMetadata {
    /// Every type PaymentSheet confirms: `PaymentSheet.supportedPaymentMethods` plus Link.
    static var nativeTypes: [STPPaymentMethodType] {
        return PaymentSheet.supportedPaymentMethods + [.link]
    }

    struct Table {
        var entries: [String: ConfirmationMetadata] = [:]
        /// Entries that didn't decode or map, and duplicates.
        var problems: [String] = []
    }

    /// Decodes a sidecar's `payment_method_confirmations` the way PaymentSheet does: `MobileSession.decode`, then
    /// `servedEntries`.
    static func decodeTable(_ data: Data) throws -> Table {
        var problems: [String] = []
        let session = try MobileSession.decode(data) { dropped in
            problems.append("\(dropped.key)[\(dropped.index)] didn't decode: \(dropped.error)")
        }
        let entries = servedEntries(session.paymentMethodConfirmations ?? []) { type, value in
            problems.append("\(type): \(value)")
        }
        return Table(entries: entries, problems: problems)
    }

    static let fixtureTable: Table = {
        guard
            let url = Bundle(for: ConfirmationMetadataTableTests.self).url(forResource: "payment_method_confirmations", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            return Table(problems: ["payment_method_confirmations.json isn't in the test bundle"])
        }
        do {
            return try decodeTable(data)
        } catch {
            return Table(problems: ["payment_method_confirmations.json didn't decode: \(error)"])
        }
    }()

    /// The table's entry for `type`, as the server would serve it, or nil if PaymentSheet doesn't confirm it.
    static func native(for type: STPPaymentMethodType) -> ConfirmationMetadata? {
        guard nativeTypes.contains(type) else {
            return nil
        }
        return fixtureTable.entries[type.identifier]
    }
}

extension ConfirmationMetadata {
    /// The table's entries as JSON, as the server sends them in `mobile_session.payment_method_confirmations`.
    static func fixtureJSONEntries() throws -> [[String: Any]] {
        let url = try XCTUnwrap(Bundle(for: ConfirmationMetadataTableTests.self).url(forResource: "payment_method_confirmations", withExtension: "json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        return try XCTUnwrap(json["payment_method_confirmations"] as? [[String: Any]])
    }
}

extension STPElementsSession {
    /// This session as if the server also served the table's entry for every type, as mint does with its
    /// `elements_mobile_payment_method_confirmations` flag on, so `PaymentConfirmer` confirms every native type.
    func _testServingConfirmationTable() throws -> STPElementsSession {
        let flag = PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled
        PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = true
        defer { PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled = flag }
        var json = allResponseFields
        var mobileSession = json[MobileSession.sidecarResponseKey] as? [String: Any] ?? [:]
        mobileSession["payment_method_confirmations"] = try ConfirmationMetadata.fixtureJSONEntries()
        json[MobileSession.sidecarResponseKey] = mobileSession
        return try XCTUnwrap(STPElementsSession.decodedObject(fromAPIResponse: json))
    }
}

extension PaymentConfirmerFamily {
    /// The table's types in this family.
    var types: [STPPaymentMethodType] {
        return ConfirmationMetadata.nativeTypes.filter { type in
            ConfirmationMetadata.native(for: type).map(PaymentConfirmerFamily.init(metadata:)) == self
        }
    }
}

// MARK: - Tests

/// The table fixture must be complete and fully understood, so the harnesses compare every type.
final class ConfirmationMetadataTableTests: XCTestCase {
    func testTableDecodesWithoutProblems() {
        // When the table is loaded through the sidecar decoder and the served-entry mapping
        let table = ConfirmationMetadata.fixtureTable

        // Then every entry decodes and maps, with no unparsable value, missing field or duplicate
        XCTAssertEqual(table.problems, [])
    }

    func testTableCoversEveryNativeType() {
        let table = ConfirmationMetadata.fixtureTable
        // Every type PaymentSheet confirms has an entry
        for type in ConfirmationMetadata.nativeTypes {
            XCTAssertNotNil(table.entries[type.identifier], "\(type.identifier) isn't in the table")
        }
        // ...and nothing else
        XCTAssertEqual(Set(table.entries.keys), Set(ConfirmationMetadata.nativeTypes.map(\.identifier)))
    }

    func testFamiliesComeFromTheEntries() {
        // Each type's family comes from its entry alone
        let expected: [PaymentConfirmerFamily: Set<STPPaymentMethodType>] = [
            .voucher: [.OXXO, .boleto, .konbini, .multibanco],
            .noNextAction: [.SEPADebit, .bacsDebit, .AUBECSDebit, .USBankAccount],
            .appToApp: [.cashApp, .swish, .alipay],
            .pollingScreen: [.blik, .mbWay, .bizum, .paynow, .promptPay, .pix],
            .stripeSDK: [.card, .link],
        ]
        for (family, types) in expected {
            XCTAssertEqual(Set(family.types), types, "\(family)")
        }
        // ...and every other type is a redirect
        let others = Set(ConfirmationMetadata.nativeTypes).subtracting(expected.values.reduce(Set(), { $0.union($1) }))
        XCTAssertEqual(Set(PaymentConfirmerFamily.redirect.types), others)
        XCTAssertTrue(PaymentConfirmerFamily.redirect.types.contains(.klarna))
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
        // Given the table, whose entries are what the server serves (no SDK-internal fields)
        let table = ConfirmationMetadata.fixtureTable
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

    func testPollingScreensCarryEnglishStrings() throws {
        // Given the table's polling screens
        let table = ConfirmationMetadata.fixtureTable
        for type in PollingViewModel.supportedPaymentMethods {
            let entry = try XCTUnwrap(table.entries[type.identifier])
            let screens = entry.nextActions.values.compactMap { nextAction -> ConfirmationMetadata.NextAction.PollingScreen? in
                if case .pollingScreen(let screen, _) = nextAction.presenter { return screen } else { return nil }
            }
            let screen = try XCTUnwrap(screens.first, type.identifier)
            // Then each has the server's English strings, with a literal {time_remaining} only when it counts down
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
            setup: MobileSession.SetupSupport(supported: false)
        )
    }
}
