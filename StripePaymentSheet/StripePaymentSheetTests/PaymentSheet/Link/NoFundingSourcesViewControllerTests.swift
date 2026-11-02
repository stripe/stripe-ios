//
//  NoFundingSourcesViewControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 10/29/26.
//

import Foundation
import StripeCoreTestUtils
import StripePaymentsTestUtils
@_spi(InternalOnlyAPI) import StripeUICore
import XCTest

@testable @_spi(InternalOnlyAPI) @_spi(CryptoOnrampAlpha) import StripePaymentSheet

@MainActor
// @iOS26
final class NoFundingSourcesViewControllerSnapshotTests: STPSnapshotTestCase {

    override static func setUp() {
        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }
    }

    func testDefault() {
        let sut = NoFundingSourcesViewControllerTestHelpers.makeSUT()
        verify(sut.view)
    }

    func testCannotContinueWithoutLink() {
        let sut = NoFundingSourcesViewControllerTestHelpers.makeSUT(canContinueWithoutLink: false)
        verify(sut.view)
    }

    func testDarkMode() {
        let sut = NoFundingSourcesViewControllerTestHelpers.makeSUT()
        sut.overrideUserInterfaceStyle = .dark
        verify(sut.view)
    }

    func testCustomLinkAppearance() {
        let sut = NoFundingSourcesViewControllerTestHelpers.makeSUT(
            linkAppearance: LinkAppearance(
                colors: .init(primary: .systemPurple, contentOnPrimary: .white),
                primaryButton: .init(cornerRadius: 4, height: 48)
            )
        )
        verify(sut.view)
    }

    private func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

@MainActor
final class NoFundingSourcesViewControllerTests: XCTestCase {

    func testPayAnotherWayReturnsToPaymentSheet() throws {
        // Given the error screen shown from a flow that can continue without Link
        let coordinator = MockPayWithLinkCoordinator()
        let sut = NoFundingSourcesViewControllerTestHelpers.makeSUT()
        sut.coordinator = coordinator
        sut.loadViewIfNeeded()

        // When the user taps "Pay another way"
        try XCTUnwrap(sut.view.findButton(titled: String.Localized.pay_another_way)).sendActions(for: .touchUpInside)

        // Then Link is canceled and the user returns to the payment sheet
        XCTAssertEqual(coordinator.cancelCalls, [true])
        XCTAssertEqual(coordinator.logoutCalls, [])
    }

    func testLogInToAnotherAccountLogsOutWithoutCanceling() throws {
        // Given the error screen
        let coordinator = MockPayWithLinkCoordinator()
        let sut = NoFundingSourcesViewControllerTestHelpers.makeSUT()
        sut.coordinator = coordinator
        sut.loadViewIfNeeded()

        // When the user taps "Log in to another account"
        try XCTUnwrap(sut.view.findButton(titled: String.Localized.log_in_to_another_account)).sendActions(for: .touchUpInside)

        // Then the user is logged out but stays in Link to log in again
        XCTAssertEqual(coordinator.logoutCalls, [false])
        XCTAssertEqual(coordinator.cancelCalls, [])
    }

    func testHidesPayAnotherWayWhenUserCannotContinueWithoutLink() {
        // Given the error screen shown from a flow that can't continue without Link
        let sut = NoFundingSourcesViewControllerTestHelpers.makeSUT(canContinueWithoutLink: false)

        // When the view loads
        sut.loadViewIfNeeded()

        // Then only the "Log in to another account" button is shown
        XCTAssertNil(sut.view.findButton(titled: String.Localized.pay_another_way))
        XCTAssertNotNil(sut.view.findButton(titled: String.Localized.log_in_to_another_account))
    }
}

@MainActor
private enum NoFundingSourcesViewControllerTestHelpers {
    static func makeSUT(
        canContinueWithoutLink: Bool = true,
        linkAppearance: LinkAppearance? = nil
    ) -> PayWithLinkViewController.NoFundingSourcesViewController {
        let (intent, elementsSession) = try! PayWithLinkTestHelpers.makePaymentIntentAndElementsSession()
        return PayWithLinkViewController.NoFundingSourcesViewController(
            context: .init(
                intent: intent,
                elementsSession: elementsSession,
                configuration: PaymentSheet.Configuration(),
                linkBrand: .link,
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                canContinueWithoutLink: canContinueWithoutLink,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                analyticsHelper: ._testValue(),
                linkAppearance: linkAppearance
            )
        )
    }
}

@MainActor
private final class MockPayWithLinkCoordinator: PayWithLinkCoordinating {
    private(set) var cancelCalls: [Bool] = []
    private(set) var logoutCalls: [Bool] = []

    func cancel(shouldReturnToPaymentSheet: Bool) {
        cancelCalls.append(shouldReturnToPaymentSheet)
    }

    func logout(cancel: Bool) {
        logoutCalls.append(cancel)
    }

    func pushContentViewController(_ contentViewController: PayWithLinkViewController.BaseViewController) {}
    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails,
        confirmationExtras: LinkConfirmationExtras?,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {}
    func confirmWithApplePay() {}
    func startFinancialConnections(completion: @escaping (PaymentSheetResult) -> Void) {}
    func startInstantDebits(completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void) {}
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount) {}
    func finish(withResult result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {}
    func handlePaymentDetailsSelected(_ paymentDetails: ConsumerPaymentDetails, confirmationExtras: LinkConfirmationExtras) {}
    func bailToWebFlow() {}
    func allowSheetDismissal(_ enable: Bool) {}
    func cancel3DS2ChallengeFlow() {}
}

private extension UIView {
    func findButton(titled title: String) -> Button? {
        if let button = self as? Button, button.title == title {
            return button
        }
        for subview in subviews {
            if let button = subview.findButton(titled: title) {
                return button
            }
        }
        return nil
    }
}
