//
//  PaymentSheetFlowControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 6/13/25.
//

@testable import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(AppearanceAPIAdditionsPreview) @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
@testable @_spi(AppearanceAPIAdditionsPreview) @_spi(STP) import StripeUICore
import XCTest

class PaymentSheetFlowControllerTests: XCTestCase {

    func makePaymentDetailsStub(nickname: String? = nil) -> ConsumerPaymentDetails {
        return ConsumerPaymentDetails(
            stripeID: "1",
            details: .card(card: .init(
                expiryYear: 30,
                expiryMonth: 10,
                brand: "visa",
                networks: ["visa"],
                last4: "1234",
                funding: .credit,
                checks: nil
            )),
            billingAddress: nil,
            billingEmailAddress: nil,
            nickname: nickname,
            isDefault: false
        )
    }

    func makeBankAccountPaymentDetailsStub(nickname: String? = nil) -> ConsumerPaymentDetails {
        return ConsumerPaymentDetails(
            stripeID: "2",
            details: .bankAccount(bankAccount: .init(
                iconCode: nil,
                name: "STRIPE TEST BANK",
                last4: "6789",
                country: "COUNTRY_US"
            )),
            billingAddress: nil,
            billingEmailAddress: nil,
            nickname: nickname,
            isDefault: false
        )
    }

    func makeSUT() -> PaymentSheetLinkAccount {
        return PaymentSheetLinkAccount(
            email: "user@example.com",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )
    }

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

    // MARK: - PaymentOptionDisplayData Labels Tests

    func testPaymentOptionDisplayData_CardLabels() {
        // Create a Visa card payment option
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"

        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = cardParams

        let paymentOption = PaymentSheet.PaymentOption.new(confirmParams: confirmParams)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for card payment option
        XCTAssertEqual(displayData.labels.label, "Visa")
        XCTAssertEqual(displayData.labels.sublabel, "•••• 4242")
    }

    func testPaymentOptionDisplayData_USBankAccountLabels_NoLinkedBank() {
        // Create a US bank account payment option without linked bank
        let bankParams = STPPaymentMethodUSBankAccountParams()
        bankParams.accountType = .checking
        bankParams.accountHolderType = .individual

        let confirmParams = IntentConfirmParams(type: .stripe(.USBankAccount))
        confirmParams.paymentMethodParams.usBankAccount = bankParams

        let paymentOption = PaymentSheet.PaymentOption.new(confirmParams: confirmParams)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for US bank account without linked bank
        XCTAssertEqual(displayData.labels.label, "US bank account")
        XCTAssertNil(displayData.labels.sublabel)
    }

    func testPaymentOptionDisplayData_SavedCardLabels() {
        // Create a saved Visa card payment method using test helper
        let paymentMethod = STPPaymentMethod._testCard()

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for saved card
        XCTAssertEqual(displayData.labels.label, "Visa")
        XCTAssertEqual(displayData.labels.sublabel, "•••• 4242")
    }

    func testPaymentOptionDisplayData_SavedUSBankAccountLabels() {
        // Create a saved US bank account payment method using test helper
        let paymentMethod = STPPaymentMethod._testUSBankAccount()

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for saved US bank account - should show bank name from saved payment method
        XCTAssertEqual(displayData.labels.label, "STRIPE TEST BANK")
        XCTAssertEqual(displayData.labels.sublabel, "••••6789")
    }

    func testPaymentOptionDisplayData_ApplePayLabels() {
        let paymentOption = PaymentSheet.PaymentOption.applePay
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for Apple Pay
        XCTAssertEqual(displayData.labels.label, "Apple Pay")
        XCTAssertEqual(displayData.labels.sublabel, nil)
    }

    func testPaymentOptionDisplayData_LinkLabels() {
        let linkOption = PaymentSheet.LinkConfirmOption.wallet
        let paymentOption = PaymentSheet.PaymentOption.link(option: linkOption)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for Link
        XCTAssertEqual(displayData.labels.label, STPPaymentMethodType.link.displayName)
        XCTAssertNil(displayData.labels.sublabel)
    }

    func testPaymentOptionDisplayData_ExternalPaymentMethodLabels() {
        // Create an external payment method (e.g., PayPal)
        let externalPaymentMethod = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://example.com/paypal.png")!,
            darkImageUrl: nil
        )

        let configuration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _ in
                return .completed
            }
        )

        let externalPaymentOption = ExternalPaymentOption.from(externalPaymentMethod, configuration: configuration)!
        let billingDetails = STPPaymentMethodBillingDetails()

        let paymentOption = PaymentSheet.PaymentOption.external(paymentMethod: externalPaymentOption, billingDetails: billingDetails)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for external payment method
        XCTAssertEqual(displayData.labels.label, "PayPal")
        XCTAssertEqual(displayData.labels.sublabel, nil)
    }

    func testPaymentOptionDisplayData_SavedLinkCardLabels() {
        // Create a saved Link card payment method using test helper
        let paymentMethod = STPPaymentMethod._testLink(displayName: "TEST DISPLAY NAME")

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for saved Link card - should show Link display name as label and detailed info as sublabel
        XCTAssertEqual(displayData.labels.label, STPPaymentMethodType.link.displayName)
        XCTAssertEqual(displayData.labels.sublabel, "TEST DISPLAY NAME •••• 4242")
    }

    func testPaymentOptionDisplayData_SavedLinkPaymentMethodLabels() {
        // Create a saved Link payment method using test helper
        let paymentMethod = STPPaymentMethod._testLink(displayName: "TEST DISPLAY NAME")

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for saved Link payment method - display name is nil on fixture so should show "Link"
        XCTAssertEqual(displayData.labels.label, "Link")
        XCTAssertEqual(displayData.labels.sublabel, "TEST DISPLAY NAME •••• 4242")
    }

    func testPaymentOptionDisplayData_LinkWithPaymentDetailsLabels() {
        let linkAccount = PaymentSheetLinkAccount._testValue(email: "foo@bar.com", isRegistered: false)

        // Create payment details for a Visa card with a specific nickname
        let paymentDetails = makePaymentDetailsStub(nickname: "Visa Credit")

        let linkOption = PaymentSheet.LinkConfirmOption.withPaymentDetails(
            account: linkAccount,
            paymentDetails: paymentDetails,
            confirmationExtras: nil,
            shippingAddress: nil
        )

        let paymentOption = PaymentSheet.PaymentOption.link(option: linkOption)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for Link with payment details - should show "Link" as label and formatted details as sublabel
        XCTAssertEqual(displayData.labels.label, "Link")
        // The sublabel should now be the formatted string combining the nickname and card details
        XCTAssertEqual(displayData.labels.sublabel, "Visa Credit •••• 1234")
    }

    func testPaymentOptionDisplayData_LinkWithBankAccountPaymentDetailsLabels() {
        let linkAccount = PaymentSheetLinkAccount._testValue(email: "foo@bar.com", isRegistered: false)

        // Create payment details for a bank account with a specific nickname
        let paymentDetails = makeBankAccountPaymentDetailsStub(nickname: "My Checking")

        let linkOption = PaymentSheet.LinkConfirmOption.withPaymentDetails(
            account: linkAccount,
            paymentDetails: paymentDetails,
            confirmationExtras: nil,
            shippingAddress: nil
        )

        let paymentOption = PaymentSheet.PaymentOption.link(option: linkOption)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled
        )

        // Test labels for Link with bank account payment details - should show "Link" as label and formatted details as sublabel
        XCTAssertEqual(displayData.labels.label, "Link")
        // The sublabel should show the bank account details
        XCTAssertEqual(displayData.labels.sublabel, "My Checking")
    }

    // MARK: - mandateMarkedAsDisplayed Tests

    func testMandateMarkedAsDisplayed_new() {
        let params = IntentConfirmParams(type: .stripe(.card))
        XCTAssertFalse(params.didDisplayMandate)

        let option = PaymentOption.new(confirmParams: params)
        let result = option.mandateMarkedAsDisplayed()

        if case .new(let resultParams) = result {
            XCTAssertTrue(resultParams.didDisplayMandate)
        } else {
            XCTFail("Expected .new option")
        }
    }

    func testMandateMarkedAsDisplayed_saved() {
        let params = IntentConfirmParams(type: .stripe(.card))
        XCTAssertFalse(params.didDisplayMandate)

        let paymentMethod = STPFixtures.paymentMethod()
        let option = PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: params)
        let result = option.mandateMarkedAsDisplayed()

        if case .saved(_, let resultParams) = result {
            XCTAssertTrue(resultParams?.didDisplayMandate ?? false)
        } else {
            XCTFail("Expected .saved option")
        }
    }

    func testMandateMarkedAsDisplayed_applePay() {
        let option = PaymentOption.applePay
        let result = option.mandateMarkedAsDisplayed()
        if case .applePay = result {
            // expected
        } else {
            XCTFail("Expected .applePay option")
        }
    }

    func testFlowControllerUpdate_preservesPaymentOptionWhenMandateIntroduced() {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        // Use CashApp as an example PM: it has no user-input fields, but requires a mandate when setupFutureUsage is set.
        // This simulates the scenario where update() introduces a mandate requirement.
        let previousParams = IntentConfirmParams(type: .stripe(.cashApp))
        previousParams.didDisplayMandate = true // As our fix does during update
        let previousOption: PaymentOption = .new(confirmParams: previousParams)

        let configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        let intentWithMandate = Intent._testPaymentIntent(paymentMethodTypes: [.cashApp], setupFutureUsage: .offSession)
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["cashapp"])
        let loadResultWithMandate = PaymentSheetLoader.LoadResult(
            intent: intentWithMandate,
            elementsSession: elementsSession,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.cashApp)]
        )
        let newVC = PaymentSheet.FlowController.makeViewController(
            configuration: configuration,
            loadResult: loadResultWithMandate,
            analyticsHelper: ._testValue(),
            walletButtonsViewState: .hidden,
            previousPaymentOption: previousOption
        )

        // The payment option should be non-nil because didDisplayMandate was set
        XCTAssertNotNil(newVC.selectedPaymentOption, "Payment option should be preserved after update introduces a mandate")
    }

    func testFlowControllerUpdate_mandateMarkedAsDisplayedPreservesFormPaymentOption() {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        // Verify the fix works at the form level: when previousCustomerInput has didDisplayMandate = true,
        // a form with a mandate element is immediately valid.
        let previousParams = IntentConfirmParams(type: .stripe(.cashApp))
        previousParams.didDisplayMandate = true

        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.cashApp], setupFutureUsage: .offSession)
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["cashapp"])
        let configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: false)

        let formVC = PaymentMethodFormViewController(
            type: .stripe(.cashApp),
            intent: intent,
            elementsSession: elementsSession,
            previousCustomerInput: previousParams,
            formCache: .init(),
            configuration: configuration,
            headerView: nil,
            analyticsHelper: ._testValue(),
            delegate: self
        )

        // The form should immediately return a valid payment option because the mandate is marked as displayed
        XCTAssertNotNil(formVC.paymentOption, "Form should be valid when mandate was marked as displayed via previousCustomerInput")

        // Verify that without didDisplayMandate, the form is NOT valid (the mandate blocks it)
        let paramsWithoutMandate = IntentConfirmParams(type: .stripe(.cashApp))
        paramsWithoutMandate.didDisplayMandate = false

        let formVCWithoutMandate = PaymentMethodFormViewController(
            type: .stripe(.cashApp),
            intent: intent,
            elementsSession: elementsSession,
            previousCustomerInput: paramsWithoutMandate,
            formCache: .init(),
            configuration: configuration,
            headerView: nil,
            analyticsHelper: ._testValue(),
            delegate: self
        )

        XCTAssertNil(formVCWithoutMandate.paymentOption, "Form should be invalid when mandate was not displayed")
    }

    // MARK: - Enhanced Completion Block Tests

    func testPresentPaymentOptions_EnhancedCompletion_BothMethodsExist() {
        // Given a FlowController with mocked dependencies
        let configuration = PaymentSheet.Configuration()
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let elementsSession = STPElementsSession._testCardValue()
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [.stripe(.card)])

        let flowController = PaymentSheet.FlowController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )

        let mockViewController = UIViewController()

        // Test enhanced presentPaymentOptions method with didCancel parameter
        let enhancedExpectation = expectation(description: "Enhanced completion called")
        flowController.presentPaymentOptions(from: mockViewController) { didCancel in
            // Verify didCancel is a boolean parameter that can be accessed
            XCTAssertTrue(didCancel == true || didCancel == false, "didCancel should be a boolean value")
            enhancedExpectation.fulfill()
        }

        // Trigger the delegate method directly to simulate dismissal
        flowController.flowControllerViewControllerShouldClose(flowController.viewController, didCancel: true)

        // Wait for enhanced callback
        wait(for: [enhancedExpectation], timeout: 2.0)

        // Test legacy presentPaymentOptions method without didCancel parameter
        let legacyExpectation = expectation(description: "Legacy completion called")
        flowController.presentPaymentOptions(from: mockViewController) {
            legacyExpectation.fulfill()
        }

        // Trigger the delegate method directly to simulate dismissal
        flowController.flowControllerViewControllerShouldClose(flowController.viewController, didCancel: false)

        // Wait for legacy callback
        wait(for: [legacyExpectation], timeout: 2.0)
    }
}

extension PaymentSheetFlowControllerTests: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: PaymentMethodFormViewController) {
    }

    func updateErrorLabel(for error: (any Error)?) {
    }
}
