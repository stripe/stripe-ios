//
//  PaymentSheetVerticalViewControllerTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 6/4/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheetVerticalViewControllerTest: XCTestCase {

    override func setUpWithError() throws {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                PaymentMethodFormViewController.clearFormCache()
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testInitialScreen() {
        func makeViewController(loadResult: PaymentSheetLoader.LoadResult) -> PaymentSheetVerticalViewController {
            return PaymentSheetVerticalViewController(
                configuration: ._testValue_MostPermissive(),
                loadResult: loadResult,
                isFlowController: false,
                previousPaymentOption: nil
            )

        }
        // TODO: Test other things like `selectedPaymentOption`
        // If there are saved PMs, always show the list, even if there's only one other PM
        let savedPMsLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [._testCard()],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        XCTAssertTrue(makeViewController(loadResult: savedPMsLoadResult).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have only one payment method and it collects user input, display the form directly
        let formDirectlyResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        XCTAssertTrue(makeViewController(loadResult: formDirectlyResult).children.first is PaymentMethodFormViewController)

        // If there are no saved payment methods and we have only one payment method and it doesn't collect user input, display the list
        let onlyOnePM = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [._testCard()],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        XCTAssertTrue(makeViewController(loadResult: onlyOnePM).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have multiple PMs, display the list
        let multiplePMs = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [._testCard()],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        XCTAssertTrue(makeViewController(loadResult: multiplePMs).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have one PM and Link, display the list
        let onePMAndLink = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [._testCard()],
            isLinkEnabled: true,
            isApplePayEnabled: false
        )
        XCTAssertTrue(makeViewController(loadResult: onePMAndLink).children.first is VerticalPaymentMethodListViewController)

        // If there are no saved payment methods and we have one PM and Apple Pay, display the list
        let onePMAndApplePay = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [._testCard()],
            isLinkEnabled: false,
            isApplePayEnabled: true
        )
        XCTAssertTrue(makeViewController(loadResult: onePMAndApplePay).children.first is VerticalPaymentMethodListViewController)
    }
}
