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

    func verify(_ sut: PaymentSheetVerticalViewController, identifier: String? = nil) {
        let bottomSheet = BottomSheetViewController(contentViewController: sut, appearance: .default, isTestMode: false, didCancelNative3DS2: {})
        let height = bottomSheet.view.systemLayoutSizeFitting(.init(width: 375, height: UIView.noIntrinsicMetric)).height
        bottomSheet.view.frame = .init(origin: .zero, size: .init(width: 375, height: height))
        STPSnapshotVerifyView(bottomSheet.view, identifier: identifier)
    }

    // Test when we display the PM list upon initialization
    func testDisplaysList() {
        func makeSUT(loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool) -> PaymentSheetVerticalViewController {
            return .init(configuration: ._testValue_MostPermissive(), loadResult: loadResult, isFlowController: isFlowController, previousPaymentOption: nil)
        }

        // 1. Saved PMs
        let loadResult1 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [._testCard()],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        verify(makeSUT(loadResult: loadResult1, isFlowController: false), identifier: "saved_pms")

        // 2. No saved payment methods and we have only one payment method and it's not a card
        let loadResult2 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.SEPADebit]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        verify(makeSUT(loadResult: loadResult2, isFlowController: false), identifier: "one_non_card_pm")

        // 3. No saved payment methods and we have multiple PMs
        let loadResult3 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .SEPADebit]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        verify(makeSUT(loadResult: loadResult3, isFlowController: false), identifier: "multiple_pms")

        // 4. No saved payment methods and we have one PM and Link and Apple Pay in FlowController, so they're in the list
        let loadResult4 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [],
            isLinkEnabled: true,
            isApplePayEnabled: true
        )
        verify(makeSUT(loadResult: loadResult4, isFlowController: true), identifier: "card_link_applepay_flowcontroller")

        // 5. No saved payment methods and we have one PM and Apple Pay in FlowController, so it's in the list
        let loadResult5 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: true
        )
        verify(makeSUT(loadResult: loadResult5, isFlowController: true), identifier: "card_applepay_flowcontroller")
    }

    // Test when we display the form directly upon initialization instead of the payment method list
    func testDisplaysFormDirectly() {
        // Makes VC w/ no saved PMs and card
        func makeSUT(isLinkEnabled: Bool, isApplePayEnabled: Bool, isFlowController: Bool) -> PaymentSheetVerticalViewController {
            let loadResult = PaymentSheetLoader.LoadResult(
                intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
                savedPaymentMethods: [],
                isLinkEnabled: isLinkEnabled,
                isApplePayEnabled: isApplePayEnabled
            )
            return PaymentSheetVerticalViewController(configuration: .init(), loadResult: loadResult, isFlowController: isFlowController, previousPaymentOption: nil)
        }
        // 1. No saved payment methods, only one payment method and it's card
        verify(makeSUT(isLinkEnabled: false, isApplePayEnabled: false, isFlowController: false))

        // 2. #1 + Apple Pay
        verify(makeSUT(isLinkEnabled: false, isApplePayEnabled: true, isFlowController: false), identifier: "apple_pay")

        // 3. #1 + Apple Pay + Link
        verify(makeSUT(isLinkEnabled: true, isApplePayEnabled: true, isFlowController: false), identifier: "apple_pay_and_link")

        // 4. #1 + Link
        verify(makeSUT(isLinkEnabled: true, isApplePayEnabled: false, isFlowController: false), identifier: "link")

        // 5. #1 + Link + FlowController - Link shows as a button in this case
        verify(makeSUT(isLinkEnabled: true, isApplePayEnabled: false, isFlowController: true), identifier: "link_flowcontroller")
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
        // TODO: Assert paymentOption exactly equal
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
