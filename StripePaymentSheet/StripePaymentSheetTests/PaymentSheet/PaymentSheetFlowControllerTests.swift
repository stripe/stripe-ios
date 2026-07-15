//
//  PaymentSheetFlowControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 6/13/25.
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
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

    // MARK: - Enhanced Completion Block Tests

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
        let completedSession = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: {
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

    // MARK: - PaymentOption billing details

    func testPaymentOptionBillingDetails_savedFallsBackToPaymentMethodBillingDetails() {
        // No confirm params -> use the PM's billing details
        let paymentMethod = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: nil)

        XCTAssertEqual(paymentOption.billingDetails?.address?.country, "US")
        XCTAssertEqual(paymentOption.billingDetails?.address?.line1, "123 Main St")
    }

    func testPaymentOptionBillingDetails_savedPrefersConfirmParams() {
        // Confirm params win when present
        let paymentMethod = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        let billingDetails = STPPaymentMethodBillingDetails()
        let address = STPPaymentMethodAddress()
        address.country = "CA"
        billingDetails.address = address
        confirmParams.paymentMethodParams.billingDetails = billingDetails
        let paymentOption = PaymentSheet.PaymentOption.saved(paymentMethod: paymentMethod, confirmParams: confirmParams)

        XCTAssertEqual(paymentOption.billingDetails?.address?.country, "CA")
    }

    // MARK: - Intent.checkoutRequiringBillingSync

    @MainActor
    func testCheckoutRequiringBillingSync() async throws {
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let savedCard = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        let savedOption = PaymentSheet.PaymentOption.saved(paymentMethod: savedCard, confirmParams: nil)

        // Non-checkout intent
        XCTAssertNil(Intent._testPaymentIntent(paymentMethodTypes: [.card]).checkoutRequiringBillingSync(for: savedOption))
        // No selection (e.g. deleted all SPMs)
        XCTAssertNil(Intent.checkout(checkout).checkoutRequiringBillingSync(for: nil))
        // Apple Pay has no billingDetails
        XCTAssertNil(PaymentSheet.PaymentOption.applePay.billingDetails)
        XCTAssertNil(Intent.checkout(checkout).checkoutRequiringBillingSync(for: .applePay))
        // Different billing than the session
        let requiringSync = Intent.checkout(checkout).checkoutRequiringBillingSync(for: savedOption)
        XCTAssertNotNil(requiringSync)
        XCTAssertEqual(requiringSync?.billingDetails.address?.country, "US")
        XCTAssertEqual(requiringSync?.billingDetails.address?.line1, "123 Main St")

        // Already matches
        try await checkout.syncBillingAddress(from: savedOption.billingDetails)
        XCTAssertNil(Intent.checkout(checkout).checkoutRequiringBillingSync(for: savedOption))
    }

    @MainActor
    func testCheckoutRequiringBillingSync_zipOnlySavedCard_stillHasCountry() async {
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let zipOnlyCard = STPPaymentMethod._testCard(postalCode: "12345", countryCode: "US")
        let savedOption = PaymentSheet.PaymentOption.saved(paymentMethod: zipOnlyCard, confirmParams: nil)

        XCTAssertEqual(savedOption.billingDetails?.address?.country, "US")
        XCTAssertEqual(savedOption.billingDetails?.address?.postalCode, "12345")
        XCTAssertNotNil(Intent.checkout(checkout).checkoutRequiringBillingSync(for: savedOption))
    }

    @MainActor
    func testCheckoutRequiringBillingSync_updatedPMBillingDiffersFromSession() async throws {
        // PM billing changed (e.g. via update form); next commit should need a sync.
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let original = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        try await checkout.syncBillingAddress(from: PaymentSheet.PaymentOption.saved(paymentMethod: original, confirmParams: nil).billingDetails)
        XCTAssertEqual(checkout.session.billingAddress?.address.postalCode, "94105")

        let updated = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "99999", countryCode: "US")
        let updatedOption = PaymentSheet.PaymentOption.saved(paymentMethod: updated, confirmParams: nil)

        let requiringSync = Intent.checkout(checkout).checkoutRequiringBillingSync(for: updatedOption)
        XCTAssertNotNil(requiringSync)
        XCTAssertEqual(requiringSync?.billingDetails.address?.postalCode, "99999")
    }

    @MainActor
    func testCheckoutRequiringBillingSync_newPaymentOption() async {
        // Continue with a newly entered card (not an SPM) should still sync billing.
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        let billingDetails = STPPaymentMethodBillingDetails()
        let address = STPPaymentMethodAddress()
        address.country = "US"
        address.postalCode = "12345"
        billingDetails.address = address
        confirmParams.paymentMethodParams.billingDetails = billingDetails
        let newOption = PaymentSheet.PaymentOption.new(confirmParams: confirmParams)

        let requiringSync = Intent.checkout(checkout).checkoutRequiringBillingSync(for: newOption)
        XCTAssertNotNil(requiringSync)
        XCTAssertEqual(requiringSync?.billingDetails.address?.country, "US")
        XCTAssertEqual(requiringSync?.billingDetails.address?.postalCode, "12345")
    }

    @MainActor
    func testCheckoutRequiringBillingSync_newPaymentOptionMissingCountry_skips() async {
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        let billingDetails = STPPaymentMethodBillingDetails()
        let address = STPPaymentMethodAddress()
        address.postalCode = "12345"
        billingDetails.address = address
        confirmParams.paymentMethodParams.billingDetails = billingDetails
        let newOption = PaymentSheet.PaymentOption.new(confirmParams: confirmParams)

        XCTAssertNil(Intent.checkout(checkout).checkoutRequiringBillingSync(for: newOption))
    }

    // MARK: - Intent.syncCheckoutBillingIfNeeded

    @MainActor
    func testSyncBillingIfNeeded_nothingToSync_closesImmediately() async {
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let savedCard = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        let savedOption = PaymentSheet.PaymentOption.saved(paymentMethod: savedCard, confirmParams: nil)

        try? await checkout.syncBillingAddress(from: savedOption.billingDetails)

        var loadingStates: [Bool] = []
        var failed = false
        var closed = false
        Intent.checkout(checkout).syncCheckoutBillingIfNeeded(
            for: savedOption,
            setLoading: { loadingStates.append($0) },
            onFailure: { _ in failed = true },
            completion: { closed = true }
        )

        XCTAssertTrue(closed)
        XCTAssertTrue(loadingStates.isEmpty)
        XCTAssertFalse(failed)
    }

    @MainActor
    func testSyncBillingIfNeeded_nilSelection_preservesSessionBilling() async throws {
        // Nil selection (deleted all SPMs) should close without clearing existing session billing.
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let savedCard = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        try await checkout.syncBillingAddress(from: PaymentSheet.PaymentOption.saved(paymentMethod: savedCard, confirmParams: nil).billingDetails)
        XCTAssertEqual(checkout.session.billingAddress?.address.country, "US")

        var loadingStates: [Bool] = []
        var failed = false
        var closed = false
        Intent.checkout(checkout).syncCheckoutBillingIfNeeded(
            for: nil,
            setLoading: { loadingStates.append($0) },
            onFailure: { _ in failed = true },
            completion: { closed = true }
        )

        XCTAssertTrue(closed)
        XCTAssertTrue(loadingStates.isEmpty)
        XCTAssertFalse(failed)
        XCTAssertEqual(checkout.session.billingAddress?.address.country, "US")
        XCTAssertEqual(checkout.session.billingAddress?.address.line1, "123 Main St")
    }

    @MainActor
    func testSyncBillingIfNeeded_differentAddress_syncsThenCloses() async {
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let savedCard = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        let savedOption = PaymentSheet.PaymentOption.saved(paymentMethod: savedCard, confirmParams: nil)

        var loadingStates: [Bool] = []
        var failed = false
        let closed = expectation(description: "closed")
        Intent.checkout(checkout).syncCheckoutBillingIfNeeded(
            for: savedOption,
            setLoading: { loadingStates.append($0) },
            onFailure: { _ in failed = true },
            completion: { closed.fulfill() }
        )

        // Loading starts synchronously before the async work
        XCTAssertEqual(loadingStates, [true])
        await fulfillment(of: [closed], timeout: 2.0)

        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertFalse(failed)
        XCTAssertEqual(checkout.session.billingAddress?.address.country, "US")
        XCTAssertEqual(checkout.session.billingAddress?.address.line1, "123 Main St")
    }

    @MainActor
    func testSyncBillingIfNeeded_newPaymentOption_syncsThenCloses() async {
        // Mirrors Continue with a newly entered card.
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        let billingDetails = STPPaymentMethodBillingDetails()
        let address = STPPaymentMethodAddress()
        address.country = "US"
        address.postalCode = "12345"
        billingDetails.address = address
        confirmParams.paymentMethodParams.billingDetails = billingDetails
        let newOption = PaymentSheet.PaymentOption.new(confirmParams: confirmParams)

        var loadingStates: [Bool] = []
        var failed = false
        let closed = expectation(description: "closed")
        Intent.checkout(checkout).syncCheckoutBillingIfNeeded(
            for: newOption,
            setLoading: { loadingStates.append($0) },
            onFailure: { _ in failed = true },
            completion: { closed.fulfill() }
        )

        XCTAssertEqual(loadingStates, [true])
        await fulfillment(of: [closed], timeout: 2.0)

        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertFalse(failed)
        XCTAssertEqual(checkout.session.billingAddress?.address.country, "US")
        XCTAssertEqual(checkout.session.billingAddress?.address.postalCode, "12345")
    }

    @MainActor
    func testSyncBillingIfNeeded_updatedPMBilling_syncsOnCommit() async throws {
        // Updating SPM billing does not sync by itself; the next commit should.
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let original = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        try await checkout.syncBillingAddress(from: PaymentSheet.PaymentOption.saved(paymentMethod: original, confirmParams: nil).billingDetails)
        XCTAssertEqual(checkout.session.billingAddress?.address.postalCode, "94105")

        let updated = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "99999", countryCode: "US")
        let updatedOption = PaymentSheet.PaymentOption.saved(paymentMethod: updated, confirmParams: nil)

        var loadingStates: [Bool] = []
        var failed = false
        let closed = expectation(description: "closed")
        Intent.checkout(checkout).syncCheckoutBillingIfNeeded(
            for: updatedOption,
            setLoading: { loadingStates.append($0) },
            onFailure: { _ in failed = true },
            completion: { closed.fulfill() }
        )

        await fulfillment(of: [closed], timeout: 2.0)

        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertFalse(failed)
        XCTAssertEqual(checkout.session.billingAddress?.address.postalCode, "99999")
        XCTAssertEqual(checkout.session.billingAddress?.address.line1, "123 Main St")
    }

    @MainActor
    func testSyncBillingIfNeeded_syncFails_callsOnFailureAndDoesNotClose() async {
        // When the server update fails, stay open: onFailure fires, completion does not.
        let apiClient = APIStubbedTestCase.stubbedAPIClient()
        let stubDescriptor = stub(condition: { request in
            request.url?.absoluteString.contains("/v1/payment_pages") == true
                || request.url?.absoluteString.contains("/v1/checkout/sessions") == true
        }) { _ in
            let body = ["error": ["message": "Billing update failed", "type": "api_error"]]
            return HTTPStubsResponse(jsonObject: body, statusCode: 500, headers: nil)
        }
        defer {
            HTTPStubs.removeStub(stubDescriptor)
        }

        var json = CheckoutTestHelpers.openSessionJSON
        json["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.billing",
        ]
        let session = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: json)!
        let checkout = await Checkout(
            clientSecret: "cs_test_123_secret_abc",
            apiResponse: session,
            apiClient: apiClient
        )
        XCTAssertTrue(
            checkout.session.shouldSendTaxRegion(for: "billing"),
            "Test requires a tax-enabled session so sync hits the network"
        )

        let savedCard = STPPaymentMethod._testCard(line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105", countryCode: "US")
        let savedOption = PaymentSheet.PaymentOption.saved(paymentMethod: savedCard, confirmParams: nil)

        var loadingStates: [Bool] = []
        var receivedError: Error?
        var closed = false
        let failed = expectation(description: "onFailure")
        Intent.checkout(checkout).syncCheckoutBillingIfNeeded(
            for: savedOption,
            setLoading: { loadingStates.append($0) },
            onFailure: {
                receivedError = $0
                failed.fulfill()
            },
            completion: { closed = true }
        )

        await fulfillment(of: [failed], timeout: 2.0)

        XCTAssertFalse(closed)
        XCTAssertEqual(loadingStates, [true, false])
        XCTAssertNotNil(receivedError)
        XCTAssertNil(checkout.session.billingAddress)
    }

}
