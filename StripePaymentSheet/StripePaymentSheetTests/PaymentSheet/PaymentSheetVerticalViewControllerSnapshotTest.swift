//
//  PaymentSheetVerticalViewControllerSnapshotTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 5/20/24.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @_spi(EarlyAccessCVCRecollectionFeature) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheetVerticalViewControllerSnapshotTest: STPSnapshotTestCase {
    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func makeBottomSheetAndLayout(_ sut: PaymentSheetVerticalViewController) -> BottomSheetViewController {
        let bottomSheet = BottomSheetViewController(contentViewController: sut, appearance: .default, isTestMode: false, didCancelNative3DS2: {})
        bottomSheet.view.setNeedsLayout()
        bottomSheet.view.layoutIfNeeded()
        let height = bottomSheet.view.systemLayoutSizeFitting(.init(width: 375, height: UIView.noIntrinsicMetric)).height
        bottomSheet.view.frame = .init(origin: .zero, size: .init(width: 375, height: height))
        return bottomSheet
    }

    func verify(_ sut: PaymentSheetVerticalViewController, identifier: String? = nil) {
        let bottomSheet = makeBottomSheetAndLayout(sut)
        STPSnapshotVerifyView(bottomSheet.view, identifier: identifier)
    }

    // Test when we display the PM list upon initialization
    func testDisplaysList() {
        func makeSUT(loadResult: PaymentSheetLoader.LoadResult, isApplePayEnabled: Bool, isFlowController: Bool) -> PaymentSheetVerticalViewController {
            var config = PaymentSheet.Configuration._testValue_MostPermissive()
            if !isApplePayEnabled {
                config.applePay = nil
            }
            return .init(configuration: config, loadResult: loadResult, isFlowController: isFlowController, analyticsHelper: ._testValue(), previousPaymentOption: nil)
        }

        // 1. Saved PMs
        let loadResult1 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()]
        )
        verify(makeSUT(loadResult: loadResult1, isApplePayEnabled: false, isFlowController: false), identifier: "saved_pms")

        // 2. No saved payment methods and we have only one payment method and it's not a card
        let loadResult2 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.SEPADebit]),
            elementsSession: ._testValue(paymentMethodTypes: ["sepa_debit"]),
            savedPaymentMethods: []
        )
        verify(makeSUT(loadResult: loadResult2, isApplePayEnabled: false, isFlowController: false), identifier: "one_non_card_pm")

        // 3. No saved payment methods and we have multiple PMs
        let loadResult3 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .SEPADebit]),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "sepa_debit"]),
            savedPaymentMethods: []
        )
        verify(makeSUT(loadResult: loadResult3, isApplePayEnabled: false, isFlowController: false), identifier: "multiple_pms")

        // 4. No saved payment methods and we have one PM and Link and Apple Pay in FlowController, so they're in the list
        let loadResult4 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
            savedPaymentMethods: []
        )
        verify(makeSUT(loadResult: loadResult4, isApplePayEnabled: true, isFlowController: true), identifier: "card_link_applepay_flowcontroller")

        // 5. No saved payment methods and we have one PM and Apple Pay in FlowController, so it's in the list
        let loadResult5 = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: []
        )
        verify(makeSUT(loadResult: loadResult5, isApplePayEnabled: true, isFlowController: true), identifier: "card_applepay_flowcontroller")
    }

    // Test when we display the form directly upon initialization instead of the payment method list
    func testDisplaysFormDirectly() {
        // Makes VC w/ no saved PMs and card
        func makeSUT(isLinkEnabled: Bool, isApplePayEnabled: Bool, isFlowController: Bool) -> PaymentSheetVerticalViewController {
            var config = PaymentSheet.Configuration._testValue_MostPermissive()
            let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: isLinkEnabled, disableLinkSignup: true)
            if !isApplePayEnabled {
                config.applePay = nil
            }
            let loadResult = PaymentSheetLoader.LoadResult(
                intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
                elementsSession: elementsSession,
                savedPaymentMethods: []
            )
            return PaymentSheetVerticalViewController(configuration: config, loadResult: loadResult, isFlowController: isFlowController, analyticsHelper: ._testValue(), previousPaymentOption: nil)
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
            elementsSession: ._testValue(paymentMethodTypes: ["card", "cashapp"]),
            savedPaymentMethods: []
        )
        // ...and previous customer input is card...
        let previousPaymentOption = PaymentOption.new(confirmParams: IntentConfirmParams(params: ._testValidCardValue(), type: .stripe(.card)))
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(), loadResult: loadResult, isFlowController: true, analyticsHelper: ._testValue(), previousPaymentOption: previousPaymentOption)
        // ...should display card form w/ fields filled out & back button
        verify(sut)
        // TODO: Assert paymentOption exactly equal
    }

    func testRestoresPreviousCustomerInputWithFormAndNoOtherPMs() {
        // When loaded with only card and nothing else...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: []
        )
        // ...and previous customer input is card...
        let previousPaymentOption = PaymentOption.new(confirmParams: IntentConfirmParams(params: ._testValidCardValue(), type: .stripe(.card)))
        let sut = PaymentSheetVerticalViewController(configuration: .init(), loadResult: loadResult, isFlowController: true, analyticsHelper: ._testValue(), previousPaymentOption: previousPaymentOption)
        // ...should display card form w/ fields filled out & *no back button*
        verify(sut)
    }

    func testRestoresPreviousCustomerInputWithoutForm() {
        // When loaded with card and cash app and nothing else...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .cashApp]),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "cashapp"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: []
        )
        // ...and previous customer input is cash app - a PM without a form
        let previousPaymentOption = PaymentOption.new(confirmParams: IntentConfirmParams(type: .stripe(.cashApp)))
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.applePay = nil
        let sut = PaymentSheetVerticalViewController(configuration: configuration, loadResult: loadResult, isFlowController: true, analyticsHelper: ._testValue(), previousPaymentOption: previousPaymentOption)
        // ...should display list with cash app selected
        verify(sut)
    }

    func testRestoresPreviousCustomerInputWithInvalidType() {
        // When loaded with card and cash app and nothing else...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .cashApp]),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "cashapp"]),
            savedPaymentMethods: []
        )
        // ...and previous customer input is SEPA - a PM that is not in the list
        let previousPaymentOption = PaymentOption.new(confirmParams: IntentConfirmParams(type: .stripe(.SEPADebit)))
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(isApplePayEnabled: false), loadResult: loadResult, isFlowController: true, analyticsHelper: ._testValue(), previousPaymentOption: previousPaymentOption)
        // ...should display list without anything selected
        verify(sut)
    }

    func testDisplaysMandateBelowList_cashapp() {
        // When loaded with cash app + sfu = off_session...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .cashApp], setupFutureUsage: .offSession),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "cashapp"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: []
        )
        // ...and previous customer input is cash app - a PM without a form...
        let previousPaymentOption = PaymentOption.new(confirmParams: IntentConfirmParams(type: .stripe(.cashApp)))
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(isApplePayEnabled: false), loadResult: loadResult, isFlowController: true, analyticsHelper: ._testValue(), previousPaymentOption: previousPaymentOption)
        // ...should display list with cash app selected and mandate displayed
        verify(sut)
    }

    func testDisplaysMandateBelowList_saved_sepa_debit() {
        // When loaded with saved SEPA Debit PM...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .SEPADebit]),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "sepa_debit"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: [._testSEPA()]
        )
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(isApplePayEnabled: false), loadResult: loadResult, isFlowController: true, analyticsHelper: ._testValue(), previousPaymentOption: nil)
        // ...should display list with saved SEPA selected and mandate displayed
        verify(sut)
    }

    func testDisplaysMandateBelowList_saved_us_bank_account() {
        // When loaded with saved US Bank Account PM...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .USBankAccount]),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "us_bank_account"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: [._testUSBankAccount()]
        )
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(isApplePayEnabled: false), loadResult: loadResult, isFlowController: true, analyticsHelper: ._testValue(), previousPaymentOption: nil)
        // ...should display list with saved SEPA selected and mandate displayed
        verify(sut)
    }

    func testDisplaysError() {
        struct MockError: LocalizedError {
            var errorDescription: String?{
                "Mock error description"
            }
        }
        // When loaded with US Bank (an example PM)...
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testDeferredIntent(paymentMethodTypes: [.USBankAccount, .cashApp], setupFutureUsage: .offSession),
            elementsSession: ._testValue(paymentMethodTypes: ["us_bank_account", "cashapp"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: []
        )
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(isApplePayEnabled: false), loadResult: loadResult, isFlowController: true, analyticsHelper: ._testValue(), previousPaymentOption: nil)
        // ...and an error is set...
        sut.updateErrorLabel(for: MockError())
        // ...we should display the error
        verify(sut, identifier: "under_list")

        // Take another snapshot displaying the mandate
        let listVC = sut.paymentMethodListViewController!
        listVC.didTap(rowButton: listVC.getRowButton(accessibilityIdentifier: "Cash App Pay"), selection: .new(paymentMethodType: .stripe(.cashApp)))
        sut.updateErrorLabel(for: MockError())
        verify(sut, identifier: "under_list_with_mandate")

        // Take another snapshot displaying the form
        sut.didTapPaymentMethod(.new(paymentMethodType: .stripe(.USBankAccount)))
        sut.updateErrorLabel(for: MockError())
        verify(sut, identifier: "under_form")
    }

    func testAddNewCardFormTitle() {
        // If we're displaying a saved card in the list, the card form title should be "New card" and not "Card"
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: [._testCard()]
        )
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(), loadResult: loadResult, isFlowController: false, analyticsHelper: ._testValue(), previousPaymentOption: nil)
        _ = makeBottomSheetAndLayout(sut) // Laying out before calling `didTap` avoids breaking constraints due to zero size
        let listVC = sut.paymentMethodListViewController!
        listVC.didTap(rowButton: listVC.getRowButton(accessibilityIdentifier: "New card"), selection: .new(paymentMethodType: .stripe(.card)))
        verify(sut)
    }

    func testCVCRecollection() {
        let savedCard = STPPaymentMethod._testCard()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), confirmHandler: { _, _, _ in }, requireCVCRecollection: true)
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"], customerSessionData: nil, isLinkPassthroughModeEnabled: false)
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: [savedCard]
        )
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(isApplePayEnabled: false), loadResult: loadResult, isFlowController: false, analyticsHelper: ._testValue(), previousPaymentOption: nil)
        _ = makeBottomSheetAndLayout(sut) // Laying out before calling `didTap` avoids breaking constraints due to zero size
        sut.paymentSheetDelegate = self
        sut.didTapPrimaryButton()
        verify(sut)

        // Snapshot when error is CVC related
        let cvcError = NSError(domain: STPError.stripeDomain, code: STPErrorCode.cardError.rawValue, userInfo: [STPError.errorParameterKey: "cvc", NSLocalizedDescriptionKey: "Bad CVC (this is a mock string)"])
        mockConfirmResult = .failed(error: cvcError)
        sut.cvcRecollectionViewController?.cvcRecollectionElement.getTextFieldElement("CVC")?.setText("123")
        sut.didTapPrimaryButton()
        wait(seconds: PaymentSheetUI.minimumFlightTime + 1)
        self.verify(sut, identifier: "cvc_error")

        // Snapshot when error isn't CVC related
        let nonCVCError = NSError(domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue, userInfo: [NSLocalizedDescriptionKey: "Some non-CVC-specific error message."])
        mockConfirmResult = .failed(error: nonCVCError)
        sut.didTapPrimaryButton()
        wait(seconds: PaymentSheetUI.minimumFlightTime + 1)
        self.verify(sut, identifier: "non_cvc_error")
    }

    func testDisabledState() {
        let loadResult = PaymentSheetLoader.LoadResult._testValue(paymentMethodTypes: ["card", "us_bank_account"], savedPaymentMethods: [._testCard()])
        let sut = PaymentSheetVerticalViewController(configuration: ._testValue_MostPermissive(isApplePayEnabled: true), loadResult: loadResult, isFlowController: false, analyticsHelper: ._testValue(), previousPaymentOption: nil)
        sut.isUserInteractionEnabled = false
        self.verify(sut)
    }

    var mockConfirmResult: StripePaymentSheet.PaymentSheetResult = .canceled
}

extension PaymentSheetVerticalViewControllerSnapshotTest: PaymentSheetViewControllerDelegate {
    func paymentSheetViewControllerShouldConfirm(_ paymentSheetViewController: any StripePaymentSheet.PaymentSheetViewControllerProtocol, with paymentOption: StripePaymentSheet.PaymentOption, completion: @escaping (StripePaymentSheet.PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) {
        completion(mockConfirmResult, nil)
    }

    func paymentSheetViewControllerDidFinish(_ paymentSheetViewController: any StripePaymentSheet.PaymentSheetViewControllerProtocol, result: StripePaymentSheet.PaymentSheetResult) {

    }

    func paymentSheetViewControllerDidCancel(_ paymentSheetViewController: any StripePaymentSheet.PaymentSheetViewControllerProtocol) {
    }

    func paymentSheetViewControllerDidSelectPayWithLink(_ paymentSheetViewController: any StripePaymentSheet.PaymentSheetViewControllerProtocol) {
    }
}
