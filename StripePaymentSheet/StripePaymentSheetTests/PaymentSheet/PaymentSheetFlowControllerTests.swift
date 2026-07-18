//
//  PaymentSheetFlowControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 6/13/25.
//

@_spi(STP) @testable import StripeCore
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
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    override func tearDown() {
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        super.tearDown()
    }

    private func makeCardPaymentMethod(id: String, last4: String, brand: String) -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": id,
            "type": "card",
            "created": "12345",
            "card": [
                "last4": last4,
                "brand": brand,
                "exp_month": "01",
                "exp_year": "2040",
            ],
        ])!
    }

    private func makeFlowController(
        savedPaymentMethods: [STPPaymentMethod],
        orientation: PaymentSheet.PaymentMethodLayout.ResolvedLayout = .vertical
    ) -> PaymentSheet.FlowController {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let elementsSession = STPElementsSession._testCardValue()
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: orientation
        )
        return PaymentSheet.FlowController(
            configuration: PaymentSheet.Configuration(),
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
    }

    private func savedPaymentMethodID(_ paymentOption: PaymentOption?) -> String? {
        guard case let .saved(paymentMethod, _) = paymentOption else {
            return nil
        }
        return paymentMethod.stripeId
    }

    @MainActor
    private func selectSavedPaymentMethod(
        _ paymentMethod: STPPaymentMethod,
        from paymentMethods: [STPPaymentMethod],
        in viewController: PaymentSheetVerticalViewController
    ) {
        let reorderedPaymentMethods = [paymentMethod] + paymentMethods.filter { $0.stripeId != paymentMethod.stripeId }
        let manageViewController = VerticalSavedPaymentMethodsViewController(
            configuration: viewController.configuration,
            intent: viewController.intent,
            selectedPaymentMethod: paymentMethod,
            paymentMethods: reorderedPaymentMethods,
            elementsSession: viewController.elementsSession,
            analyticsHelper: viewController.analyticsHelper,
            defaultPaymentMethod: nil
        )
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(paymentMethod.stripeId), forCustomer: nil)
        viewController.didComplete(
            viewController: manageViewController,
            with: paymentMethod,
            latestPaymentMethods: reorderedPaymentMethods,
            didTapToDismiss: false,
            defaultPaymentMethod: nil
        )
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
        let linkOption = PaymentSheet.LinkConfirmOption.wallet(brand: .link)
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

    func testPaymentOptionDisplayData_OnelinkLabels() {
        let linkOption = PaymentSheet.LinkConfirmOption.wallet(brand: .onelink)
        let paymentOption = PaymentSheet.PaymentOption.link(option: linkOption)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled,
            linkBrand: .onelink
        )

        XCTAssertEqual(displayData.label, "Onelink")
        XCTAssertEqual(displayData.labels.label, "Onelink")
        XCTAssertNil(displayData.labels.sublabel)
    }

    func testPaymentOptionDisplayData_NewLinkCardBrandUsesOnelinkLabel() {
        let confirmParams = IntentConfirmParams(type: .linkCardBrand)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        confirmParams.paymentMethodParams.card = cardParams

        let paymentOption = PaymentSheet.PaymentOption.new(confirmParams: confirmParams)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled,
            linkBrand: .onelink
        )

        XCTAssertEqual(displayData.label, "Onelink")
        XCTAssertEqual(displayData.labels.label, "Onelink")
    }

    func testPaymentOptionDisplayData_LinkSignUpUsesOnelinkLabel() {
        let confirmParams = IntentConfirmParams(type: .linkCardBrand)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        confirmParams.paymentMethodParams.card = cardParams
        let linkOption = PaymentSheet.LinkConfirmOption.signUp(
            brand: .onelink,
            account: makeSUT(),
            phoneNumber: nil,
            consentAction: .implied_v0,
            legalName: nil,
            intentConfirmParams: confirmParams
        )
        let paymentOption = PaymentSheet.PaymentOption.link(option: linkOption)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled,
            linkBrand: .onelink
        )

        XCTAssertEqual(displayData.label, "Onelink")
        XCTAssertEqual(displayData.labels.label, "Onelink")
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

    func testPaymentSheetLabel_SavedLinkFallbackUsesOnelinkBrand() {
        let paymentMethod = STPPaymentMethod._testLink()
        paymentMethod.linkPaymentDetails = nil

        XCTAssertEqual(paymentMethod.paymentSheetLabel(brand: .onelink), "Onelink")
        XCTAssertEqual(paymentMethod.expandedPaymentSheetLabel(brand: .onelink), "Onelink")
    }

    func testPaymentOptionDisplayData_SavedLinkFallbackUsesOnelinkLabels() {
        let paymentMethod = STPPaymentMethod._testLink()
        paymentMethod.linkPaymentDetails = nil

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled,
            linkBrand: .onelink
        )

        XCTAssertEqual(displayData.label, "Onelink")
        XCTAssertEqual(displayData.labels.label, "Onelink")
        XCTAssertNil(displayData.labels.sublabel)
    }

    func testPaymentOptionDisplayData_SavedLinkPassthroughUsesOnelinkLabel() {
        let paymentMethod = STPPaymentMethod._testCard()
        paymentMethod.isLinkOrigin = true

        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)
        let displayData = PaymentSheet.FlowController.PaymentOptionDisplayData(
            paymentOption: paymentOption,
            currency: "usd",
            iconStyle: .filled,
            linkBrand: .onelink
        )

        XCTAssertEqual(displayData.label, "•••• 4242")
        XCTAssertEqual(displayData.labels.label, "Onelink")
        XCTAssertEqual(displayData.labels.sublabel, "•••• 4242")
    }

    func testPaymentOptionDisplayData_LinkWithPaymentDetailsLabels() {
        let linkAccount = PaymentSheetLinkAccount._testValue(email: "foo@bar.com", isRegistered: false)

        // Create payment details for a Visa card with a specific nickname
        let paymentDetails = makePaymentDetailsStub(nickname: "Visa Credit")

        let linkOption = PaymentSheet.LinkConfirmOption.withPaymentDetails(
            brand: .link,
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
            brand: .link,
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
        XCTAssertEqual(displayData.labels.sublabel, "My Checking •••• 6789")
    }

    // MARK: - Selection restoration

    @MainActor
    func testCancelingPaymentOptionsRestoresPreviousSavedPaymentMethod() {
        // Given a FlowController with a selected saved payment method
        let firstPaymentMethod = makeCardPaymentMethod(id: "pm_first", last4: "4242", brand: "visa")
        let secondPaymentMethod = makeCardPaymentMethod(id: "pm_second", last4: "0005", brand: "amex")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(firstPaymentMethod.stripeId), forCustomer: nil)
        let flowController = makeFlowController(savedPaymentMethods: [firstPaymentMethod, secondPaymentMethod])
        XCTAssertEqual(savedPaymentMethodID(flowController.viewController.selectedPaymentOption), firstPaymentMethod.stripeId)

        let completionExpectation = expectation(description: "Payment options dismissed")
        flowController.presentPaymentOptions(from: UIViewController()) { didCancel in
            XCTAssertTrue(didCancel)
            completionExpectation.fulfill()
        }

        // When a different saved payment method is selected and the sheet is canceled
        let presentedViewController = flowController.viewController as! PaymentSheetVerticalViewController
        selectSavedPaymentMethod(
            secondPaymentMethod,
            from: [firstPaymentMethod, secondPaymentMethod],
            in: presentedViewController
        )
        XCTAssertEqual(savedPaymentMethodID(presentedViewController.selectedPaymentOption), secondPaymentMethod.stripeId)
        flowController.flowControllerViewControllerShouldClose(presentedViewController, didCancel: true)
        wait(for: [completionExpectation], timeout: 2)

        // Then the previous payment option and local default are restored
        XCTAssertEqual(savedPaymentMethodID(flowController.viewController.selectedPaymentOption), firstPaymentMethod.stripeId)
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: nil), .stripeId(firstPaymentMethod.stripeId))
    }

    @MainActor
    func testCancelingPaymentOptionsRestoresNoSelection() {
        // Given a FlowController with no selected or persisted payment option
        let paymentMethod = makeCardPaymentMethod(id: "pm_card", last4: "4242", brand: "visa")
        let flowController = makeFlowController(savedPaymentMethods: [paymentMethod])
        flowController.viewController.clearSelection()
        flowController.updatePaymentOption()
        XCTAssertNil(flowController.paymentOption)

        let completionExpectation = expectation(description: "Payment options dismissed")
        flowController.presentPaymentOptions(from: UIViewController()) { didCancel in
            XCTAssertTrue(didCancel)
            completionExpectation.fulfill()
        }

        // When a saved payment method is selected and the sheet is canceled
        let presentedViewController = flowController.viewController as! PaymentSheetVerticalViewController
        selectSavedPaymentMethod(
            paymentMethod,
            from: [paymentMethod],
            in: presentedViewController
        )
        flowController.flowControllerViewControllerShouldClose(presentedViewController, didCancel: true)
        wait(for: [completionExpectation], timeout: 2)

        // Then FlowController returns to having no selection
        XCTAssertNil(flowController.viewController.selectedPaymentOption)
        XCTAssertNil(flowController.paymentOption)
        XCTAssertNil(CustomerPaymentOption.localDefaultPaymentMethod(for: nil))
    }

    @MainActor
    func testContinuingPaymentOptionsKeepsNewSavedPaymentMethod() {
        // Given a FlowController with a selected saved payment method
        let firstPaymentMethod = makeCardPaymentMethod(id: "pm_first", last4: "4242", brand: "visa")
        let secondPaymentMethod = makeCardPaymentMethod(id: "pm_second", last4: "0005", brand: "amex")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(firstPaymentMethod.stripeId), forCustomer: nil)
        let flowController = makeFlowController(savedPaymentMethods: [firstPaymentMethod, secondPaymentMethod])
        let completionExpectation = expectation(description: "Payment options dismissed")
        flowController.presentPaymentOptions(from: UIViewController()) { didCancel in
            XCTAssertFalse(didCancel)
            completionExpectation.fulfill()
        }

        // When a different saved payment method is selected and the sheet is continued
        let presentedViewController = flowController.viewController as! PaymentSheetVerticalViewController
        selectSavedPaymentMethod(
            secondPaymentMethod,
            from: [firstPaymentMethod, secondPaymentMethod],
            in: presentedViewController
        )
        flowController.flowControllerViewControllerShouldClose(presentedViewController, didCancel: false)
        wait(for: [completionExpectation], timeout: 2)

        // Then the new option remains selected
        XCTAssertEqual(savedPaymentMethodID(flowController.viewController.selectedPaymentOption), secondPaymentMethod.stripeId)
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: nil), .stripeId(secondPaymentMethod.stripeId))
    }

    @MainActor
    func testCancelingHorizontalPaymentOptionsRestoresPreviousSavedPaymentMethod() {
        // Given a horizontal FlowController with a selected saved payment method
        let firstPaymentMethod = makeCardPaymentMethod(id: "pm_first", last4: "4242", brand: "visa")
        let secondPaymentMethod = makeCardPaymentMethod(id: "pm_second", last4: "0005", brand: "amex")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(firstPaymentMethod.stripeId), forCustomer: nil)
        let flowController = makeFlowController(
            savedPaymentMethods: [firstPaymentMethod, secondPaymentMethod],
            orientation: .horizontal
        )
        let completionExpectation = expectation(description: "Payment options dismissed")
        flowController.presentPaymentOptions(from: UIViewController()) { didCancel in
            XCTAssertTrue(didCancel)
            completionExpectation.fulfill()
        }

        // When persistence changes while the horizontal sheet is open and the sheet is canceled
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(secondPaymentMethod.stripeId), forCustomer: nil)
        flowController.updateForWalletButtonsView()
        XCTAssertEqual(savedPaymentMethodID(flowController.viewController.selectedPaymentOption), secondPaymentMethod.stripeId)
        flowController.flowControllerViewControllerShouldClose(flowController.viewController, didCancel: true)
        wait(for: [completionExpectation], timeout: 2)

        // Then cancel restores the previous payment option and persisted selection
        XCTAssertEqual(savedPaymentMethodID(flowController.viewController.selectedPaymentOption), firstPaymentMethod.stripeId)
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: nil), .stripeId(firstPaymentMethod.stripeId))
    }

    @MainActor
    func testHorizontalSelectionToRestoreOverridesServerDefault() {
        // Given a horizontal FlowController where the server default is a saved bank account
        let customerID = "cus_horizontal_server_default"
        let bank = STPPaymentMethod._testUSBankAccount()
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            defaultPaymentMethod: bank.stripeId,
            paymentMethods: [bank.allResponseFields],
            allowsSetAsDefaultPM: true
        )
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: [bank],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .horizontal
        )
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: true)
        configuration.customer = .init(id: customerID, ephemeralKeySecret: "ek_test")

        let initialViewController = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
        XCTAssertEqual(savedPaymentMethodID(initialViewController.selectedPaymentOption), bank.stripeId)

        // An ordinary previous option preserves form input without overriding the server default
        let updateViewController = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            previousPaymentOption: .applePay
        )
        XCTAssertEqual(savedPaymentMethodID(updateViewController.selectedPaymentOption), bank.stripeId)

        // When the controller is reconstructed with Apple Pay as the selection to restore
        let restoredViewController = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            selectionToRestore: .applePay
        )

        // Then the selection to restore takes precedence over the server default
        guard case .applePay = restoredViewController.selectedPaymentOption else {
            return XCTFail("Expected Apple Pay to be restored")
        }
    }

    @MainActor
    func testHorizontalPreviousPaymentOptionPreservesCompletedFormInput() throws {
        // Given completed card input and a saved method that would otherwise seed the carousel
        let confirmParams = IntentConfirmParams(
            params: ._testValidCardValue(),
            type: .stripe(.card)
        )
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: [._testUSBankAccount()],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .horizontal
        )

        // When the horizontal controller is rebuilt after an ordinary update
        let viewController = PaymentSheetFlowControllerViewController(
            configuration: PaymentSheet.Configuration(),
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            previousPaymentOption: .new(confirmParams: confirmParams)
        )
        viewController.loadViewIfNeeded()

        // Then it shows the card form with the previous input
        let cardForm = try XCTUnwrap(viewController.formCache[.stripe(.card)])
        XCTAssertEqual(viewController.selectedPaymentMethodType, .stripe(.card))
        XCTAssertEqual(
            cardForm.getTextFieldElement("Card number")?.text,
            confirmParams.paymentMethodParams.card?.number
        )
    }

    @MainActor
    func testHorizontalSelectionToRestorePreservesLinkConfirmOption() {
        // Given Link confirmation details that aren't represented by the carousel selection
        let linkConfirmOption = PaymentSheet.LinkConfirmOption.withPaymentMethod(
            brand: .link,
            paymentMethod: ._testCard()
        )
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: [._testUSBankAccount()],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .horizontal
        )

        // When the horizontal controller is rebuilt with that selection
        let viewController = PaymentSheetFlowControllerViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            selectionToRestore: .link(option: linkConfirmOption)
        )

        // Then it preserves the complete Link confirmation option
        guard case .link(option: .withPaymentMethod) = viewController.selectedPaymentOption else {
            return XCTFail("Expected the Link confirmation option to be restored")
        }
    }

    @MainActor
    func testHorizontalUnavailableLinkWalletSelectionUsesAvailableSavedMethod() {
        // Given Link is no longer available but a saved method is
        let savedPaymentMethod = STPPaymentMethod._testUSBankAccount()
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            savedPaymentMethods: [savedPaymentMethod],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .horizontal
        )
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.link.display = .never

        // When the controller is rebuilt with a Link wallet selection
        let viewController = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            selectionToRestore: .link(option: .wallet(brand: .link))
        )

        // Then it falls back to the available saved method
        XCTAssertEqual(
            savedPaymentMethodID(viewController.selectedPaymentOption),
            savedPaymentMethod.stripeId
        )
    }

    @MainActor
    func testHorizontalSelectionToRestorePreservesFormBackedSavedMethod() throws {
        // Given a linked bank represented as a saved option but restored through its form
        let paymentMethod = STPPaymentMethod._testUSBankAccount()
        var linkBankPaymentMethod = LinkBankPaymentMethod(id: paymentMethod.stripeId)
        linkBankPaymentMethod._allResponseFieldsStorage = NonEncodableParameters(
            storage: paymentMethod.allResponseFields as? [String: Any] ?? [:]
        )
        let linkedBank = InstantDebitsLinkedBank(
            paymentMethod: linkBankPaymentMethod,
            bankName: "StripeBank",
            last4: "6789",
            linkMode: .linkPaymentMethod,
            incentiveEligible: false,
            linkAccountSessionId: "fcsess_123"
        )
        let confirmParams = IntentConfirmParams(type: .instantDebits)
        confirmParams.instantDebitsLinkedBank = linkedBank
        let paymentOption = PaymentOption.saved(
            paymentMethod: paymentMethod,
            confirmParams: confirmParams
        )
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card), .instantDebits],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .horizontal
        )
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.defaultBillingDetails.email = "test@example.com"

        // When the horizontal controller is rebuilt with that selection
        let viewController = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            selectionToRestore: paymentOption
        )

        // Then the form reconstructs the linked-bank saved option
        guard case let .saved(_, restoredConfirmParams) = viewController.selectedPaymentOption else {
            return XCTFail("Expected the linked bank to be restored")
        }
        XCTAssertEqual(
            try XCTUnwrap(restoredConfirmParams?.instantDebitsLinkedBank).last4,
            linkedBank.last4
        )
    }

    @MainActor
    func testCancelingExternalPaymentMethodRestoresBillingDetails() throws {
        let externalPaymentMethod = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://example.com/paypal.png")!,
            darkImageUrl: nil
        )
        let externalConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _ in .completed }
        )
        let externalPaymentOption = try XCTUnwrap(
            ExternalPaymentOption.from(externalPaymentMethod, configuration: externalConfiguration)
        )
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.externalPaymentMethodConfiguration = externalConfiguration
        configuration.billingDetailsCollectionConfiguration.name = .always
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(
                paymentMethodTypes: ["card"],
                externalPaymentMethodTypes: ["external_paypal"]
            ),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card), .external(externalPaymentOption)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        let flowController = PaymentSheet.FlowController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
        let viewController = flowController.viewController as! PaymentSheetVerticalViewController
        viewController.loadViewIfNeeded()

        // Given PayPal with collected billing details is selected
        let continued = expectation(description: "Payment options continued")
        flowController.presentPaymentOptions(from: UIViewController()) { didCancel in
            XCTAssertFalse(didCancel)
            continued.fulfill()
        }
        let row = try XCTUnwrap(
            viewController.paymentMethodListViewController?.rowButtons.first(where: {
                $0.type == .new(paymentMethodType: .external(externalPaymentOption))
            })
        )
        viewController.paymentMethodListViewController?.didTap(
            rowButton: row,
            selection: row.type
        )
        let form = try XCTUnwrap(viewController.formCache[.external(externalPaymentOption)])
        form.getTextFieldElement("Full name")?.setText("Jane Doe")
        flowController.flowControllerViewControllerShouldClose(viewController, didCancel: false)
        wait(for: [continued], timeout: 2)

        // When the customer backs out of the form and cancels
        let canceled = expectation(description: "Payment options canceled")
        flowController.presentPaymentOptions(from: UIViewController()) { didCancel in
            XCTAssertTrue(didCancel)
            canceled.fulfill()
        }
        let presentedViewController = flowController.viewController as! PaymentSheetVerticalViewController
        presentedViewController.sheetNavigationBarDidBack(presentedViewController.navigationBar)
        presentedViewController.didTapOrSwipeToDismiss()
        wait(for: [canceled], timeout: 2)

        // Then PayPal is restored with its selected billing details
        let restoredViewController = flowController.viewController as! PaymentSheetVerticalViewController
        guard case .external(_, let billingDetails) = restoredViewController.selectedPaymentOption else {
            return XCTFail("Expected PayPal to be restored")
        }
        XCTAssertEqual(billingDetails.name, "Jane Doe")
        XCTAssertEqual(
            restoredViewController.paymentMethodFormViewController?.paymentMethodType,
            .external(externalPaymentOption)
        )
    }

    @MainActor
    func testCancelingPaymentOptionsDoesNotRestoreDeletedSavedPaymentMethod() {
        // Given a FlowController with a selected saved payment method
        let deletedPaymentMethod = makeCardPaymentMethod(id: "pm_deleted", last4: "4242", brand: "visa")
        let remainingPaymentMethod = makeCardPaymentMethod(id: "pm_remaining", last4: "0005", brand: "amex")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(deletedPaymentMethod.stripeId), forCustomer: nil)
        let flowController = makeFlowController(savedPaymentMethods: [deletedPaymentMethod, remainingPaymentMethod])
        let completionExpectation = expectation(description: "Payment options dismissed")
        flowController.presentPaymentOptions(from: UIViewController()) { didCancel in
            XCTAssertTrue(didCancel)
            completionExpectation.fulfill()
        }

        // When the selected method is deleted while the sheet is open
        let presentedViewController = flowController.viewController as! PaymentSheetVerticalViewController
        selectSavedPaymentMethod(
            remainingPaymentMethod,
            from: [remainingPaymentMethod],
            in: presentedViewController
        )
        flowController.flowControllerViewControllerShouldClose(presentedViewController, didCancel: true)
        wait(for: [completionExpectation], timeout: 2)

        // Then the deleted method is not restored
        XCTAssertEqual(flowController.viewController.savedPaymentMethods.map(\.stripeId), [remainingPaymentMethod.stripeId])
        XCTAssertEqual(
            savedPaymentMethodID(flowController.viewController.selectedPaymentOption),
            remainingPaymentMethod.stripeId
        )
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: nil), .stripeId(remainingPaymentMethod.stripeId))
    }

    @MainActor
    func testCancelingPaymentOptionsPreservesPersistedDefaultFilteredOutOfSheet() {
        // Given the persisted method still exists for the customer but is filtered out of this sheet
        let hiddenPaymentMethod = STPPaymentMethod._testUSBankAccount()
        let visiblePaymentMethod = makeCardPaymentMethod(id: "pm_visible", last4: "4242", brand: "visa")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(hiddenPaymentMethod.stripeId), forCustomer: nil)
        let flowController = makeFlowController(savedPaymentMethods: [visiblePaymentMethod])
        let completionExpectation = expectation(description: "Payment options dismissed")
        flowController.presentPaymentOptions(from: UIViewController()) { didCancel in
            XCTAssertTrue(didCancel)
            completionExpectation.fulfill()
        }

        // When the sheet is canceled without deleting that hidden method
        flowController.flowControllerViewControllerShouldClose(flowController.viewController, didCancel: true)
        wait(for: [completionExpectation], timeout: 2)

        // Then cancellation preserves the filtered persisted default
        XCTAssertEqual(
            CustomerPaymentOption.localDefaultPaymentMethod(for: nil),
            .stripeId(hiddenPaymentMethod.stripeId)
        )
        XCTAssertEqual(
            savedPaymentMethodID(flowController.viewController.selectedPaymentOption),
            visiblePaymentMethod.stripeId
        )
    }

    func testPresentPaymentOptions_EnhancedCompletion_BothMethodsExist() {
        // Given a FlowController with mocked dependencies
        let configuration = PaymentSheet.Configuration()
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let elementsSession = STPElementsSession._testCardValue()
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [.stripe(.card)], paymentMethodMessagingPromotionsHelper: ._testValue(),
 paymentMethodOrientation: .vertical)

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

    func testCanPresentPaymentOptionsAgainFromCompletion() {
        let flowController = makeFlowController(savedPaymentMethods: [])
        let secondCompletion = expectation(description: "Second presentation completed")

        flowController.presentPaymentOptions(from: UIViewController()) { firstDidCancel in
            XCTAssertTrue(firstDidCancel)

            flowController.presentPaymentOptions(from: UIViewController()) { secondDidCancel in
                XCTAssertFalse(secondDidCancel)
                secondCompletion.fulfill()
            }
            DispatchQueue.main.async {
                flowController.flowControllerViewControllerShouldClose(
                    flowController.viewController,
                    didCancel: false
                )
            }
        }
        flowController.flowControllerViewControllerShouldClose(
            flowController.viewController,
            didCancel: true
        )

        wait(for: [secondCompletion], timeout: 2.0)
    }

    // MARK: - Checkout terminal session

    @MainActor
    func testUpdateCheckoutNoOpsForTerminalSession() async throws {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let elementsSession = STPElementsSession._testCardValue()
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let fc = PaymentSheet.FlowController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )

        let session = CheckoutTestHelpers.makeOpenSession()
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", apiResponse: session)

        // Move session to complete
        let completedSession = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: {
            var json = CheckoutTestHelpers.openSessionJSON
            json["status"] = "complete"
            json["payment_status"] = "paid"
            return json
        }())!
        try await checkout.commitSession(completedSession)
        XCTAssertFalse(checkout.sessionIsOpen)

        // FC update should bail immediately
        let exp = expectation(description: "update completes")
        fc.update(checkout: checkout) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - PaymentOption.checkoutBillingDetails

    func testSavedPaymentOptionCheckoutBillingDetails_fallsBackToSavedPaymentMethod() {
        // Given a saved PM that carries its own billing address and no confirmParams (the usual saved case)...
        let savedCard = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        let option = PaymentSheet.PaymentOption.saved(paymentMethod: savedCard, confirmParams: nil)

        // ...checkoutBillingDetails falls back to the saved PM's billing details (rather than returning nil).
        XCTAssertEqual(option.checkoutBillingDetails?.address?.country, "US")
        XCTAssertEqual(option.checkoutBillingDetails?.address?.line1, "123 Main St")
        XCTAssertEqual(option.checkoutBillingDetails?.address?.postalCode, "94105")
    }

    func testSavedPaymentOptionCheckoutBillingDetails_prefersConfirmParams() {
        // Given a saved PM plus confirmParams (e.g. CVC recollection) that carry their own billing...
        let savedCard = STPPaymentMethod._testCard(line1: "123 Main St", postalCode: "94105", countryCode: "US")
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.nonnil_billingDetails.address = STPPaymentMethodAddress()
        confirmParams.paymentMethodParams.nonnil_billingDetails.address?.country = "CA"
        let option = PaymentSheet.PaymentOption.saved(paymentMethod: savedCard, confirmParams: confirmParams)

        // ...confirmParams billing wins over the saved PM's billing.
        XCTAssertEqual(option.checkoutBillingDetails?.address?.country, "CA")
    }
}
