//
//  WalletViewControllerTests.swift
//  StripePaymentSheetTests
//
//

import XCTest

@testable @_spi(STP) import StripePaymentSheet

final class WalletViewControllerTests: XCTestCase {
    @MainActor
    func testDefaultCardActionsIncludeUpdateAndRemove() throws {
        let sut = makeSUT()

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.card, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Update card",
            "Remove card",
        ])
        XCTAssertEqual(actions.map(\.style), [.default, .destructive])
    }

    @MainActor
    func testNonDefaultCardActionsIncludeSetDefaultUpdateAndRemove() throws {
        let sut = makeSUT()

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.cardWithFailingChecks, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Set as default",
            "Update card",
            "Remove card",
        ])
        XCTAssertEqual(actions.map(\.style), [.default, .default, .destructive])
    }

    @MainActor
    func testNonDefaultBankAccountActionsIncludeSetDefaultAndRemove() throws {
        let sut = makeSUT()

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.bankAccount, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Set as default",
            "Remove linked account",
        ])
        XCTAssertEqual(actions.map(\.style), [.default, .destructive])
    }

    @MainActor
    func testDefaultBankAccountActionsOnlyIncludeRemove() throws {
        var paymentMethods = LinkStubs.paymentMethods()
        paymentMethods[LinkStubs.PaymentMethodIndices.bankAccount].isDefault = true
        let sut = makeSUT(paymentMethods: paymentMethods)

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.bankAccount, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Remove linked account",
        ])
        XCTAssertEqual(actions.map(\.style), [.destructive])
    }

    @MainActor
    func testGenericPaymentMethodActionsOnlyIncludeRemove() throws {
        let sut = makeSUT()

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.genericWithDisplay, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Remove payment method"
        ])
        XCTAssertEqual(actions.map(\.style), [.destructive])
    }

    @MainActor
    func test_recordBankAccountConsentIfNeeded_firesForBankAccountWithConsentText() async {
        let consentText = "Rocket Deliveries can access account and ownership details, balances, and transactions."
        let spy = RecordConsentSpyLinkAccount()
        let sut = makeSUT(linkAccount: spy, linkPaymentMethodBankAccountDataConsent: consentText)

        let bankAccount = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.bankAccount]
        await sut.recordBankAccountConsentIfNeeded(for: bankAccount)

        XCTAssertEqual(spy.recordedConsentText, consentText)
    }

    @MainActor
    func test_recordBankAccountConsentIfNeeded_doesNotFireForCard() async {
        let consentText = "Rocket Deliveries can access account and ownership details, balances, and transactions."
        let spy = RecordConsentSpyLinkAccount()
        let sut = makeSUT(linkAccount: spy, linkPaymentMethodBankAccountDataConsent: consentText)

        let card = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card]
        await sut.recordBankAccountConsentIfNeeded(for: card)

        XCTAssertNil(spy.recordedConsentText)
    }

    @MainActor
    func test_recordBankAccountConsentIfNeeded_doesNotFireWhenConsentTextMissing() async {
        let spy = RecordConsentSpyLinkAccount()
        let sut = makeSUT(linkAccount: spy, linkPaymentMethodBankAccountDataConsent: nil)

        let bankAccount = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.bankAccount]
        await sut.recordBankAccountConsentIfNeeded(for: bankAccount)

        XCTAssertNil(spy.recordedConsentText)
    }
}

private final class RecordConsentSpyLinkAccount: PaymentSheetLinkAccount {
    private(set) var recordedConsentText: String?

    init() {
        super.init(
            email: "user@example.com",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            displayablePaymentDetails: nil,
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )
    }

    override func recordConnectionsConsentAcquired(localizedConsentText: String) async throws -> EmptyResponse {
        recordedConsentText = localizedConsentText
        return try JSONDecoder().decode(EmptyResponse.self, from: Data("{}".utf8))
    }
}

private extension WalletViewControllerTests {
    @MainActor
    func makeSUT(
        paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods(),
        linkAccount: PaymentSheetLinkAccount = LinkStubs.account(),
        linkPaymentMethodBankAccountDataConsent: String? = nil
    ) -> PayWithLinkViewController.WalletViewController {
        let (intent, elementsSession) = try! PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(
            linkPaymentMethodBankAccountDataConsent: linkPaymentMethodBankAccountDataConsent
        )
        let configuration = PaymentSheet.Configuration()

        return PayWithLinkViewController.WalletViewController(
            linkAccount: linkAccount,
            context: .init(
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                linkBrand: configuration.resolvedLinkBrand(elementsSession: elementsSession, linkAccount: nil),
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                analyticsHelper: ._testValue()
            ),
            paymentMethods: paymentMethods
        )
    }
}
