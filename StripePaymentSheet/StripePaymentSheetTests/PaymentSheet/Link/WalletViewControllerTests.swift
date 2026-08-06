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
    func testUnknownPaymentMethodActionsOnlyIncludeRemove() throws {
        let sut = makeSUT()

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.unknownWithDisplay, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Remove payment method"
        ])
        XCTAssertEqual(actions.map(\.style), [.destructive])
    }
}

private extension WalletViewControllerTests {
    @MainActor
    func makeSUT(
        paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods()
    ) -> PayWithLinkViewController.WalletViewController {
        let (intent, elementsSession) = try! PayWithLinkTestHelpers.makePaymentIntentAndElementsSession()
        let linkAccount = LinkStubs.account()
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
