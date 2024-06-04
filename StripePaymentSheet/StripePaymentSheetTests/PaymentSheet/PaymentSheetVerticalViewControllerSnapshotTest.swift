//
//  PaymentSheetVerticalViewControllerSnapshotTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 5/20/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheetVerticalViewControllerSnapshotTest: STPSnapshotTestCase {
    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
                PaymentMethodFormViewController.clearFormCache()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func verify(_ sut: PaymentSheetVerticalViewController) {
        let bottomSheet = BottomSheetViewController(contentViewController: sut, appearance: .default, isTestMode: false, didCancelNative3DS2: {})
        let height = bottomSheet.view.systemLayoutSizeFitting(.init(width: 375, height: UIView.noIntrinsicMetric)).height
        bottomSheet.view.frame = .init(origin: .zero, size: .init(width: 375, height: height))
        STPSnapshotVerifyView(bottomSheet.view)
    }

    func testDisplaysFormDirectly() {
        // If there are no saved payment methods and we have only one payment method and it collects user input, display the form instead of the payment method list.
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        let sut = PaymentSheetVerticalViewController(configuration: .init(), loadResult: loadResult, isFlowController: false, previousPaymentOption: nil)
        verify(sut)
    }
    
    func testDisplaysFormDirectly_withWallet() {
        // Same as above test, but we are showing big Apple Pay and Link buttons
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [],
            isLinkEnabled: true,
            isApplePayEnabled: true
        )
        let sut = PaymentSheetVerticalViewController(configuration: .init(), loadResult: loadResult, isFlowController: false, previousPaymentOption: nil)
        verify(sut)
    }

    func testRestoresPreviousCustomerInputWithForm() {
        // When loaded with card and cash app and nothing else...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .cashApp]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        // ...and previous customer input is card...
        let previousPaymentOption = PaymentOption.new(confirmParams: IntentConfirmParams(params: ._testValidCardValue(), type: .stripe(.card)))
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(), loadResult: loadResult, isFlowController: true, previousPaymentOption: previousPaymentOption)
        // ...should display card form w/ fields filled out & back button
        verify(sut)
    }

    func testRestoresPreviousCustomerInputWithFormAndNoOtherPMs() {
        // When loaded with only card and nothing else...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        // ...and previous customer input is card...
        let previousPaymentOption = PaymentOption.new(confirmParams: IntentConfirmParams(params: ._testValidCardValue(), type: .stripe(.card)))
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(), loadResult: loadResult, isFlowController: true, previousPaymentOption: previousPaymentOption)
        // ...should display card form w/ fields filled out & *no back button*
        verify(sut)
    }

    func testRestoresPreviousCustomerInputWithoutForm() {
        // When loaded with card and cash app and nothing else...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .cashApp]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        // ...and previous customer input is cash app - a PM without a form
        let previousPaymentOption = PaymentOption.new(confirmParams: IntentConfirmParams(type: .stripe(.cashApp)))
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(), loadResult: loadResult, isFlowController: true, previousPaymentOption: previousPaymentOption)
        // ...should display list with cash app selected
        verify(sut)
    }

    func testRestoresPreviousCustomerInputWithInvalidType() {
        // When loaded with card and cash app and nothing else...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .cashApp]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        // ...and previous customer input is SEPA - a PM that is not in the list
        let previousPaymentOption = PaymentOption.new(confirmParams: IntentConfirmParams(type: .stripe(.SEPADebit)))
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(), loadResult: loadResult, isFlowController: true, previousPaymentOption: previousPaymentOption)
        // ...should display list without anything selected
        verify(sut)
    }
}
