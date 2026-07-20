//
//  PaymentSheetFlowControllerViewControllerTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheetFlowControllerViewControllerTests: XCTestCase {
    override func setUpWithError() throws {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testHorizontalWalletButtonsViewPreventsDefaultingToExternalApplePay() {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.willUseWalletButtonsView = true

        let viewController = makeHorizontalViewController(
            configuration: configuration,
            walletButtonsViewState: .visible(allowedWallets: ["apple_pay", "link"])
        )

        XCTAssertNil(viewController.selectedPaymentOption)
    }

    func testHorizontalWalletButtonsViewRespectsAlwaysPaymentElementVisibility() {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.willUseWalletButtonsView = true
        configuration.walletButtonsVisibility.paymentElement[.applePay] = .always

        let viewController = makeHorizontalViewController(
            configuration: configuration,
            walletButtonsViewState: .visible(allowedWallets: ["apple_pay", "link"])
        )

        guard case .applePay = viewController.selectedPaymentOption else {
            return XCTFail("Expected Apple Pay to remain selectable in PaymentSheet")
        }
    }

    private func makeHorizontalViewController(
        configuration: PaymentSheet.Configuration,
        walletButtonsViewState: PaymentSheet.WalletButtonsViewState
    ) -> FlowControllerViewControllerProtocol {
        return PaymentSheet.FlowController.makeViewController(
            configuration: configuration,
            loadResult: .init(
                intent: ._testValue(),
                elementsSession: ._testValue(
                    paymentMethodTypes: ["card", "link"],
                    isLinkPassthroughModeEnabled: false
                ),
                savedPaymentMethods: [],
                paymentMethodTypes: [.stripe(.card)],
                paymentMethodOrientation: .horizontal
            ),
            analyticsHelper: ._testValue(),
            walletButtonsViewState: walletButtonsViewState
        )
    }
}
