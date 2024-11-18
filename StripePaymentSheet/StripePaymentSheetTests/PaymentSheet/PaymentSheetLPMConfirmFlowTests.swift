//
//  PaymentSheet+LPMConfirmFlowTests.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 7/18/23.
//

import SafariServices
@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import SwiftUI
import XCTest

/// These tests exercise 9 different confirm flows based on the combination of:
/// - The Stripe Intent: PaymentIntent or PaymentIntent+SFU or SetupIntent
/// - The confirmation type: "Normal" intent-first client-side confirmation or "Deferred" client-side confirmation or "Deferred" server-side confirmation
/// They can also test the presence/absence of particular fields for a payment method form e.g. the SEPA test asserts that there's a mandate element.
/// 👀  See `testIdealConfirmFlows` for an example with comments.
@MainActor
final class PaymentSheet_LPM_ConfirmFlowTests: STPNetworkStubbingTestCase {
    let window: UIWindow = UIWindow(frame: .init(x: 0, y: 0, width: 428, height: 926))

    enum MerchantCountry: String {
        case US = "us"
        case SG = "sg"
        case MY = "my"
        case BE = "be"
        case GB = "gb"
        case MX = "mex"  // The CI Backend uses "mex" instead of "mx"
        case AU = "au"
        case JP = "jp"
        case BR = "br"
        case FR = "fr"
        case TH = "th"
        case DE = "de"
        case IT = "it"

        var publishableKey: String {
            switch self {
            case .US:
                return STPTestingDefaultPublishableKey
            case .SG:
                return STPTestingSGPublishableKey
            case .MY:
                return STPTestingMYPublishableKey
            case .BE:
                return STPTestingBEPublishableKey
            case .GB:
                return STPTestingGBPublishableKey
            case .MX:
                return STPTestingMEXPublishableKey
            case .AU:
                return STPTestingAUPublishableKey
            case .JP:
                return STPTestingJPPublishableKey
            case .BR:
                return STPTestingBRPublishableKey
            case .FR:
                return STPTestingFRPublishableKey
            case .TH:
                return STPTestingTHPublishableKey
            case .DE:
                return STPTestingDEPublishableKey
            case .IT:
                return STPTestingITPublishableKey
            }
        }
    }

    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
        // Don't follow redirects for this specific tests, as we want to record
        // the body of the redirect request for UnredirectableSessionDelegate.
        self.followRedirects = false
    }

    func testSEPADebitConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .SEPADebit) { form in
            form.getTextFieldElement("Full name").setText("Foo")
            form.getTextFieldElement("Email").setText("f@z.c")
            form.getTextFieldElement("IBAN").setText("DE89370400440532013000")
            form.getTextFieldElement("Address line 1").setText("asdf")
            form.getTextFieldElement("City").setText("asdf")
            form.getTextFieldElement("ZIP").setText("12345")
            XCTAssertNotNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 17)
        }
    }

    func testAUBecsDebitConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent], currency: "AUD", paymentMethodType: .AUBECSDebit, merchantCountry: .AU) { form in
            form.getTextFieldElement("Name on account").setText("Tester McTesterface")
            form.getTextFieldElement("Email").setText("example@link.com")
            form.getTextFieldElement("BSB number").setText("000000")
            form.getTextFieldElement("Account number").setText("000123456")
            XCTAssertNotNil(form.getAUBECSMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 10)
        }
    }

    func testBancontactConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "EUR", paymentMethodType: .bancontact) { form in
            form.getTextFieldElement("Full name").setText("Foo")
            XCTAssertNil(form.getMandateElement())
            XCTAssertNil(form.getTextFieldElement("Email"))
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 3)
        }

        try await _testConfirm(intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .bancontact) { form in
            form.getTextFieldElement("Full name").setText("Foo")
            form.getTextFieldElement("Email").setText("f@z.c")
            XCTAssertNotNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 5)
        }
    }

    func testSofortConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "EUR", paymentMethodType: .sofort, defaultCountry: "AT") { form in
            XCTAssertNotNil(form.getDropdownFieldElement("Country or region"))
            XCTAssertNil(form.getTextFieldElement("Full name"))
            XCTAssertNil(form.getTextFieldElement("Email"))
            XCTAssertNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 3)
        }

        try await _testConfirm(intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .sofort, defaultCountry: "AT") { form in
            XCTAssertNotNil(form.getDropdownFieldElement("Country or region"))
            form.getTextFieldElement("Full name").setText("Foo")
            form.getTextFieldElement("Email").setText("f@z.c")
            XCTAssertNotNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 7)
        }
    }

    func testGrabPayConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "SGD",
                               paymentMethodType: .grabPay,
                               merchantCountry: .SG) { form in
            // GrabPay has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testFPXConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "MYR",
                               paymentMethodType: .FPX,
                               merchantCountry: .MY) { form in
            XCTAssertNotNil(form.getDropdownFieldElement("FPX Bank"))
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 3)
        }
    }

    func testBLIKConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "PLN", paymentMethodType: .blik, merchantCountry: .BE) { form in
            form.getTextFieldElement("BLIK code").setText("123456")
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 3)
        }
    }

    func testBacsDDConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage], currency: "GBP", paymentMethodType: .bacsDebit, merchantCountry: .GB) { form in
            form.getTextFieldElement("Full name").setText("Foo")
            form.getTextFieldElement("Email").setText("f@z.c")
            form.getTextFieldElement("Sort code").setText("108800")
            form.getTextFieldElement("Account number").setText("00012345")
            form.getTextFieldElement("Address line 1").setText("asdf")
            form.getTextFieldElement("City").setText("asdf")
            form.getTextFieldElement("ZIP").setText("12345")
            form.getCheckboxElement(startingWith: "I understand that Stripe will be collecting Direct Debits")!.isSelected = true
        }
    }

    func testAmazonPayConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "USD",
                               paymentMethodType: .amazonPay,
                               merchantCountry: .US) { form in
            // AmazonPay has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testAlmaConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "EUR",
                               paymentMethodType: .alma,
                               merchantCountry: .FR) { form in
            // Alma has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testSunbitConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "USD",
                               amount: 100000,
                               paymentMethodType: .sunbit,
                               merchantCountry: .US) { form in
            // Sunbit has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testBillieConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "EUR",
                               paymentMethodType: .billie,
                               merchantCountry: .DE) { form in
            // Billie has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testSatispayConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "EUR",
                               paymentMethodType: .satispay,
                               merchantCountry: .IT) { form in
            // Satispay has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testAlipayConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "USD",
                               paymentMethodType: .alipay,
                               merchantCountry: .US) { form in
            // Alipay has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testOXXOConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "MXN",
                               paymentMethodType: .OXXO,
                               merchantCountry: .MX) { form in
            form.getTextFieldElement("Full name").setText("Jane Doe")
            form.getTextFieldElement("Email").setText("foo@bar.com")
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 4)
        }
    }

    func testKonbiniConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "JPY",
                               paymentMethodType: .konbini,
                               merchantCountry: .JP) { form in
            form.getTextFieldElement("Full name").setText("Jane Doe")
            form.getTextFieldElement("Email").setText("foo@bar.com")
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 6)
        }
    }

    func testPayNowConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "SGD",
                               paymentMethodType: .paynow,
                               merchantCountry: .SG) { form in
            // PayNow has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testBoletoConfirmFlows() async throws {
        try await _testConfirm(
            intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent],
            currency: "BRL",
            paymentMethodType: .boleto,
            merchantCountry: .BR,
            defaultCountry: "BR"
        ) { form in
            form.getTextFieldElement("Full name").setText("Jane Doe")
            form.getTextFieldElement("Email").setText("foo@bar.com")
            form.getTextFieldElement("CPF/CPNJ").setText("00000000000")
            form.getTextFieldElement("Address line 1").setText("123 fake st")
            form.getTextFieldElement("City").setText("City")
            form.getTextFieldElement("State").setText("AC")  // Valid Brazilian state code
            form.getTextFieldElement("Postal code").setText("11111111")
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 15)
        }
    }

    func testPromptPayConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "THB",
                               paymentMethodType: .promptPay,
                               merchantCountry: .TH) { form in
            form.getTextFieldElement("Email").setText("foo@bar.com")
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 3)
        }
    }

    func testSwishConfirmFlows() async throws {
        try await _testConfirm(
            intentKinds: [.paymentIntent],
            currency: "SEK",
            paymentMethodType: .swish,
            merchantCountry: .FR
        ) { form in
            // Swish has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testMobilePayConfirmFlows() async throws {
        try await _testConfirm(
            intentKinds: [.paymentIntent],
            currency: "DKK",
            paymentMethodType: .mobilePay,
            merchantCountry: .FR
        ) { form in
            // MobilePay has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testTwintConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "CHF",
                               paymentMethodType: .twint,
                               merchantCountry: .GB) { form in
            // Twint has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testSavedSEPA() async throws {
        let customer = "cus_OaMPphpKbeixCz"  // A hardcoded customer on acct_1G6m1pFY0qyl6XeW
        let savedSepaPM = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_1NnBnhFY0qyl6XeW9ThDjAvw", // A hardcoded SEPA PM for the ^ customer
            "type": "sepa_debit",
        ])!

        // Update the API client based on the merchant country
        let apiClient = STPAPIClient(publishableKey: MerchantCountry.US.publishableKey)
        let configuration: PaymentSheet.Configuration = {
            var config = PaymentSheet.Configuration()
            config.apiClient = apiClient
            config.allowsDelayedPaymentMethods = true
            config.returnURL = "https://foo.com"
            return config
        }()

        // Confirm saved SEPA with every confirm variation
        for intentKind in IntentKind.allCases {
            for (description, intent) in try await makeTestIntents(intentKind: intentKind, currency: "eur", paymentMethod: .SEPADebit, merchantCountry: .US, customer: customer, apiClient: apiClient) {
                let e = expectation(description: "")
                // Confirm the intent with the form details
                let paymentHandler = STPPaymentHandler(apiClient: apiClient)
                PaymentSheet.confirm(
                    configuration: configuration,
                    authenticationContext: self,
                    intent: intent,
                    elementsSession: ._testValue(intent: intent),
                    paymentOption: .saved(paymentMethod: savedSepaPM, confirmParams: nil),
                    paymentHandler: paymentHandler,
                    analyticsHelper: ._testValue()
                ) { result, _  in
                    e.fulfill()
                    switch result {
                    case .failed(error: let error):
                        XCTFail("❌ \(description): PaymentSheet.confirm failed - \(error.nonGenericDescription)")
                    case .canceled:
                        XCTFail()
                    case .completed:
                        print("✅ \(description): PaymentSheet.confirm completed")
                    }
                }
                await fulfillment(of: [e], timeout: 10)
            }
        }
    }

    func testKlarnaConfirmFlows() async throws {
        for intentKind in IntentKind.allCases {
            try await _testConfirm(intentKinds: [intentKind],
                                   currency: "USD",
                                   paymentMethodType: .klarna,
                                   merchantCountry: .US) { form in
                form.getTextFieldElement("Email").setText("foo@bar.com")
                switch intentKind {
                case .paymentIntent:
                    XCTAssertNil(form.getMandateElement())
                    XCTAssertEqual(form.getAllUnwrappedSubElements().count, 6)
                case .paymentIntentWithSetupFutureUsage, .setupIntent:
                    XCTAssertNotNil(form.getMandateElement())
                    XCTAssertEqual(form.getAllUnwrappedSubElements().count, 7)
                }
            }
        }
    }

    func testMultibancoConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "EUR",
                               paymentMethodType: .multibanco,
                               merchantCountry: .US) { form in
            form.getTextFieldElement("Email").setText("foo@bar.com")
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 3)
        }
    }

    func testRevolutPayConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "GBP",
                               paymentMethodType: .revolutPay,
                               merchantCountry: .GB) { form in
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
    }

    func testPayPalConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "EUR",
                               paymentMethodType: .payPal,
                               merchantCountry: .FR) { form in
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
        try await _testConfirm(intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent],
                               currency: "EUR",
                               paymentMethodType: .payPal,
                               merchantCountry: .FR) { form in
            XCTAssertNotNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 2)
        }
    }

    func testCashAppConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "USD",
                               paymentMethodType: .cashApp,
                               merchantCountry: .US) { form in
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
        }
        try await _testConfirm(intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent],
                               currency: "USD",
                               paymentMethodType: .cashApp,
                               merchantCountry: .US) { form in
            XCTAssertNotNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 2)
        }
    }

    // MARK: Add tests above this line
    // MARK: - 👋 👨‍🏫  Look at this test to understand how to write your own tests in this file
    func testiDEALConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "EUR", paymentMethodType: .iDEAL) { form in
            // Fill out your payment method form in here.
            // Note: Each required field you fill out implicitly tests that the field exists; if the field doesn't exist, the test will fail because the form is incomplete.
            form.getTextFieldElement("Full name").setText("Foo")
            XCTAssertNotNil(form.getDropdownFieldElement("iDEAL Bank"))
            // You can also explicitly assert for the existence/absence of certain elements.
            // e.g. iDEAL shouldn't show a mandate or email field for a vanilla payment
            XCTAssertNil(form.getMandateElement())
            XCTAssertNil(form.getTextFieldElement("Email"))
            // Asserting the total number of elements prevents accidentally adding more elements to this form
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 5)
            // Tip: To help you debug, run `po form` in the debug console or `call debugPrint(form)`
        }

        // If your payment method shows different fields depending on the kind of intent, you can call `_testConfirm` multiple times with different intents.
        // e.g. iDEAL should show an email field and mandate for PI+SFU and SIs, so we test those separately here:
        try await _testConfirm(intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .iDEAL) { form in
            form.getTextFieldElement("Full name").setText("Foo")
            form.getTextFieldElement("Email").setText("f@z.c")
            XCTAssertNotNil(form.getDropdownFieldElement("iDEAL Bank"))
            XCTAssertNotNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 7)
        }
    }
}

// MARK: - Billing detail configuration tests
extension PaymentSheet_LPM_ConfirmFlowTests {
    func testCard_OnlyCardInfo_WithDefaults() async throws {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.name = .never

        try await _testConfirm(
            intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent],
            currency: "USD",
            paymentMethodType: .card,
            configuration: configuration
        ) { form in
            form.getCardSection().panElement.setText("4242424242424242")
            form.getCardSection().expiryElement.setText("1228")
            form.getCardSection().cvcElement.setText("123")
            // No ZIP or country fields
            XCTAssertNil(form.getTextFieldElement("ZIP"))
            XCTAssertNil(form.getDropdownFieldElement("Country or region"))
        }
    }

    func testCard_AllFields_WithDefaults() async throws {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .full
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = true
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "(310) 555-1234"
        configuration.defaultBillingDetails.address.line1 = "123 Main Street"
        configuration.defaultBillingDetails.address.line2 = "line 2"
        configuration.defaultBillingDetails.address.city = "San Francisco"
        configuration.defaultBillingDetails.address.state = "California"
        configuration.defaultBillingDetails.address.country = "US"
        configuration.defaultBillingDetails.address.postalCode = "12345"

        try await _testConfirm(
            intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent],
            currency: "USD",
            paymentMethodType: .card,
            configuration: configuration
        ) { form in
            form.getCardSection().panElement.setText("4242424242424242")
            form.getCardSection().expiryElement.setText("1228")
            form.getCardSection().cvcElement.setText("123")

            // Check billing details
            XCTAssertEqual(form.getTextFieldElement("Name on card").text, "Jane Doe")
            XCTAssertEqual(form.getPhoneNumberElement().phoneNumber, .fromE164("+13105551234"))
            XCTAssertEqual(form.getTextFieldElement("Email").text, "foo@bar.com")
            XCTAssertEqual(form.getTextFieldElement("Address line 1").text, "123 Main Street")
            XCTAssertEqual(form.getTextFieldElement("Address line 2").text, "line 2")
            XCTAssertEqual(form.getTextFieldElement("City").text, "San Francisco")
            XCTAssertEqual(form.getDropdownFieldElement("State").rawData, "CA")
            XCTAssertEqual(form.getDropdownFieldElement("Country or region").rawData, "US")
            XCTAssertEqual(form.getTextFieldElement("ZIP").text, "12345")
        }
    }
}

// MARK: - Helper methods
extension PaymentSheet_LPM_ConfirmFlowTests {
    enum IntentKind: CaseIterable {
        case paymentIntent
        case paymentIntentWithSetupFutureUsage
        case setupIntent
    }

    func _testConfirm(
        intentKinds: [IntentKind],
        currency: String,
        amount: Int? = nil,
        paymentMethodType: STPPaymentMethodType,
        merchantCountry: MerchantCountry = .US,
        configuration: PaymentSheet.Configuration? = nil,
        defaultCountry: String = "US",
        formCompleter: (PaymentMethodElement) -> Void
    ) async throws {
        for intentKind in intentKinds {
            try await _testConfirm(
                intentKind: intentKind,
                currency: currency,
                amount: amount,
                paymentMethodType: paymentMethodType,
                merchantCountry: merchantCountry,
                configuration: configuration,
                defaultCountry: defaultCountry,
                formCompleter: formCompleter
            )
        }
    }

    /// A helper method that creates a form for the given `paymentMethodType` and tests three confirmation flows successfully complete:
    /// 1. normal" client-side confirmation
    /// 2. deferred client-side confirmation
    /// 3. deferred server-side
    /// - Parameter intentKind: Which kind of Intent you want to test.
    /// - Parameter currency: A valid currency for the payment method you're testing
    /// - Parameter merchantCountry: An enum representing the merchant's country
    /// - Parameter paymentMethodType: The payment method type you're testing
    /// - Parameter formCompleter: A closure that takes the form for your payment method. Your implementaiton should fill in the form's textfields etc. You can also perform additional checks e.g. to ensure certain fields are shown/hidden.
    @MainActor
    func _testConfirm(
        intentKind: IntentKind,
        currency: String,
        amount: Int? = nil,
        paymentMethodType: STPPaymentMethodType,
        merchantCountry: MerchantCountry = .US,
        configuration: PaymentSheet.Configuration? = nil,
        defaultCountry: String,
        formCompleter: (PaymentMethodElement) -> Void
    ) async throws {
        // Initialize PaymentSheet at least once to set the correct payment_user_agent for this process:
        let ic = PaymentSheet.IntentConfiguration(mode: .setup(), confirmHandler: { _, _, _ in })
        _ = PaymentSheet(mode: .deferredIntent(ic), configuration: PaymentSheet.Configuration())

        // Update the API client based on the merchant country
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)

        var configuration: PaymentSheet.Configuration = {
            // Use argument if non-nil, otherwise create a default
            if let configuration {
                return configuration
            }
            var config = PaymentSheet.Configuration()
            config.allowsDelayedPaymentMethods = true
            config.returnURL = "https://foo.com"
            config.allowsPaymentMethodsRequiringShippingAddress = true
            return config
        }()
        configuration.apiClient = apiClient

        let intents = try await makeTestIntents(intentKind: intentKind, currency: currency, amount: amount, paymentMethod: paymentMethodType, merchantCountry: merchantCountry, apiClient: apiClient)

        // Check that the form respects billingDetailsCollection
        verifyFormRespectsBillingDetailsCollectionConfiguration(paymentMethodType: paymentMethodType, defaultCountry: defaultCountry)

        for (description, intent) in intents {

            func makeFormVC(previousCustomerInput: IntentConfirmParams?) -> PaymentMethodFormViewController {
                return PaymentMethodFormViewController(type: .stripe(paymentMethodType), intent: intent, elementsSession: ._testValue(intent: intent), previousCustomerInput: previousCustomerInput, formCache: .init(), configuration: configuration, headerView: nil, analyticsHelper: ._testValue(), delegate: self)
            }
            // Make the form
            let formVC = makeFormVC(previousCustomerInput: nil)
            let paymentMethodForm = formVC.form

            // Add to window to avoid layout errors due to zero size and presentation errors
            window.rootViewController = formVC

            // Simulate view appearance. This makes SimpleMandateElement mark its mandate as having been displayed.
            formVC.viewDidAppear(false)

            // Fill out the form
            formCompleter(paymentMethodForm)

            // Generate params from the form
            guard let intentConfirmParams = paymentMethodForm.updateParams(params: IntentConfirmParams(type: .stripe(paymentMethodType))) else {
                XCTFail("Form failed to create params. Validation state: \(paymentMethodForm.validationState) \n Form: \(paymentMethodForm)")
                return
            }

            // Re-generate the form and validate that it carries over all previous customer input
            let regeneratedFormVC = makeFormVC(previousCustomerInput: intentConfirmParams)
            guard let regeneratedIntentConfirmParams = regeneratedFormVC.form.updateParams(params: IntentConfirmParams(type: .stripe(paymentMethodType))) else {
                XCTFail("Regenerated form failed to create params. Validation state: \(regeneratedFormVC.form.validationState) \n Form: \(regeneratedFormVC.form)")
                return
            }
            XCTAssertEqual(regeneratedIntentConfirmParams, intentConfirmParams)

            let e = expectation(description: "Confirm")
            let paymentHandler = STPPaymentHandler(apiClient: apiClient)
            var redirectShimCalled = false
            paymentHandler._redirectShim = { _, _, _ in
                // This gets called instead of the PaymentSheet.confirm callback if the Intent is successfully confirmed and requires next actions.
                print("✅ \(description): Successfully confirmed the intent and saw a redirect attempt.")
                // Defer this until after the `.succeeded` call is made in the below PaymentSheetAuthenticationContext
                // if applicable, so that we don't re-fetch the PI unintentionally
                DispatchQueue.main.async {
                    if paymentHandler.isInProgress {
                        paymentHandler._handleWillForegroundNotification()
                    }
                }
                redirectShimCalled = true
            }

            // Hack to PaymentSheet-specific local actions that happen before control is handed over to STPPaymentHandler.
            PaymentSheet._preconfirmShim = { viewController in
                if paymentMethodType == .bacsDebit {
                    ((viewController as! UIHostingController<BacsDDMandateView>).rootView).confirmAction()
                }
            }

            // Confirm the intent with the form details
            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: self,
                intent: intent,
                elementsSession: ._testValue(intent: intent),
                paymentOption: .new(confirmParams: intentConfirmParams),
                paymentHandler: paymentHandler,
                analyticsHelper: ._testValue()
            ) { result, _  in
                switch result {
                case .failed(error: let error):
                    XCTFail("❌ \(description): PaymentSheet.confirm failed - \(error.nonGenericDescription)")
                case .canceled:
                    XCTAssertTrue(redirectShimCalled, "❌ \(description): PaymentSheet.confirm canceled")
                case .completed:
                    print("✅ \(description): PaymentSheet.confirm completed")
                }
                e.fulfill()
            }
            await fulfillment(of: [e], timeout: 25)
        }
    }

    func makeTestIntents(
        intentKind: IntentKind,
        currency: String,
        amount: Int? = nil,
        paymentMethod: STPPaymentMethodType,
        merchantCountry: MerchantCountry,
        customer: String? = nil,
        apiClient: STPAPIClient
    ) async throws -> [(String, Intent)] {
        let paramsForServerSideConfirmation: [String: Any] = [ // We require merchants to set some extra parameters themselves for server-side confirmation
            "return_url": "foo://bar",
            "mandate_data": [
                "customer_acceptance": [
                    "type": "online",
                    "online": [
                        "user_agent": "123",
                        "ip_address": "172.18.117.125",
                    ],
                ] as [String: Any],
            ],
        ]
        func makeDeferredIntent(_ intentConfig: PaymentSheet.IntentConfiguration) -> Intent {
            return .deferredIntent(intentConfig: intentConfig)
        }

        var intents: [(String, Intent)]
        let paymentMethodTypes = [paymentMethod.identifier].compactMap { $0 }
        switch intentKind {
        case .paymentIntent:
            let paymentIntent: STPPaymentIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customer
                )
                return try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }()

            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: amount ?? 1099, currency: currency)) { _, _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customer
                )
            }

            intents = [
                ("PaymentIntent", .paymentIntent(paymentIntent)),
                ("Deferred PaymentIntent - client side confirmation", makeDeferredIntent(deferredCSC)),
            ]
            guard paymentMethod != .blik else {
                // Blik doesn't support server-side confirmation
                return intents
            }
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: amount ?? 1099, currency: currency)) { paymentMethod, _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    paymentMethodID: paymentMethod.stripeId,
                    customerID: customer,
                    confirm: true,
                    otherParams: paramsForServerSideConfirmation
                )
            }

            intents += [
                ("Deferred PaymentIntent - server side confirmation", makeDeferredIntent(deferredSSC)),
            ]

            return intents
        case .paymentIntentWithSetupFutureUsage:
            let paymentIntent: STPPaymentIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customer,
                    otherParams: ["setup_future_usage": "off_session"]
                )
                return try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }()
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: amount ?? 1099, currency: currency, setupFutureUsage: .offSession)) { _, _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customer,
                    otherParams: ["setup_future_usage": "off_session"]
                )
            }
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: amount ?? 1099, currency: currency, setupFutureUsage: .offSession)) { paymentMethod, _ in
                let otherParams = [
                    "setup_future_usage": "off_session",
                ].merging(paramsForServerSideConfirmation) { _, b in b }
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    paymentMethodID: paymentMethod.stripeId,
                    customerID: customer,
                    confirm: true,
                    otherParams: otherParams
                )
            }
            return [
                ("PaymentIntent w/ setup_future_usage", .paymentIntent(paymentIntent)),
                ("Deferred PaymentIntent w/ setup_future_usage - client side confirmation", makeDeferredIntent(deferredCSC)),
                ("Deferred PaymentIntent w/ setup_future_usage - server side confirmation", makeDeferredIntent(deferredSSC)),
            ]
        case .setupIntent:
            let setupIntent: STPSetupIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes, merchantCountry: merchantCountry.rawValue, customerID: customer)
                return try await apiClient.retrieveSetupIntent(clientSecret: clientSecret)
            }()
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { _, _ in
                return try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes, merchantCountry: merchantCountry.rawValue, customerID: customer)
            }
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { paymentMethod, _ in
                return try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes, merchantCountry: merchantCountry.rawValue, paymentMethodID: paymentMethod.stripeId, customerID: customer, confirm: true, otherParams: paramsForServerSideConfirmation)
            }
            return [
                ("SetupIntent", .setupIntent(setupIntent)),
                ("Deferred SetupIntent - client side confirmation", makeDeferredIntent(deferredCSC)),
                ("Deferred SetupIntent - server side confirmation", makeDeferredIntent(deferredSSC)),
            ]
        }
    }

    func verifyFormRespectsBillingDetailsCollectionConfiguration(paymentMethodType: STPPaymentMethodType, defaultCountry: String) {
        let addressSpec = AddressSpecProvider.shared.addressSpec(for: defaultCountry)
        func getName(from form: PaymentMethodElement) -> TextFieldElement? {
            switch paymentMethodType {
            case .card:
                return form.getTextFieldElement("Name on card")
            case .AUBECSDebit:
                return form.getTextFieldElement("Name on account")
            default:
                return form.getTextFieldElement("Full name")
            }
        }

        func getState(from form: PaymentMethodElement) -> TextOrDropdownElement? {
            let label = addressSpec.stateNameType.localizedLabel // e.g. "State", "Province"
            // Most countries use a text field for state but some (e.g. US) use a dropdown
            return form.getTextFieldElement(label) ?? form.getDropdownFieldElement(label)
        }

        // When set to .never, should not show any billing fields
        var noFieldsConfig = PaymentSheet.Configuration()
        noFieldsConfig.billingDetailsCollectionConfiguration.name = .never
        noFieldsConfig.billingDetailsCollectionConfiguration.email = .never
        noFieldsConfig.billingDetailsCollectionConfiguration.phone = .never
        noFieldsConfig.billingDetailsCollectionConfiguration.address = .never
        var form = PaymentSheetFormFactory(intent: ._testPaymentIntent(paymentMethodTypes: [paymentMethodType]), elementsSession: .emptyElementsSession, configuration: .paymentSheet(noFieldsConfig), paymentMethod: .stripe(paymentMethodType)).make()

        XCTAssertNil(getName(from: form))
        XCTAssertNil(form.getTextFieldElement("Email"))
        XCTAssertNil(form.getPhoneNumberElement())
        XCTAssertNil(form.getTextFieldElement("Address line 1"))
        XCTAssertNil(form.getTextFieldElement("Address line 2"))
        XCTAssertNil(form.getTextFieldElement(addressSpec.cityNameType.localizedLabel))
        XCTAssertNil(getState(from: form))
        // Klarna and Sofort have a bug where the country is still shown; rather than change this and potentially break integrations,
        // we'll preserve existing behavior until the next major version
        if ![.klarna, .sofort].contains(paymentMethodType) {
            XCTAssertNil(form.getDropdownFieldElement("Country or region"))
        }
        XCTAssertNil(form.getTextFieldElement(addressSpec.zipNameType.localizedLabel))

        // When set to .always, should show all billing fields
        var allFieldsConfig = PaymentSheet.Configuration()
        allFieldsConfig.billingDetailsCollectionConfiguration.name = .always
        allFieldsConfig.billingDetailsCollectionConfiguration.email = .always
        allFieldsConfig.billingDetailsCollectionConfiguration.phone = .always
        allFieldsConfig.billingDetailsCollectionConfiguration.address = .full
        form = PaymentSheetFormFactory(intent: ._testPaymentIntent(paymentMethodTypes: [paymentMethodType]), elementsSession: .emptyElementsSession, configuration: .paymentSheet(allFieldsConfig), paymentMethod: .stripe(paymentMethodType)).make()
        XCTAssertNotNil(getName(from: form))
        XCTAssertNotNil(form.getTextFieldElement("Email"))
        XCTAssertNotNil(form.getPhoneNumberElement())
        XCTAssertNotNil(form.getTextFieldElement("Address line 1"))
        XCTAssertNotNil(form.getTextFieldElement("Address line 2"))
        XCTAssertNotNil(form.getTextFieldElement(addressSpec.cityNameType.localizedLabel))
        // Some countries don't have states/provinces
        if addressSpec.fieldOrdering.contains(.state) {
            XCTAssertNotNil(getState(from: form))
        }
        XCTAssertNotNil(form.getDropdownFieldElement("Country or region"))
        XCTAssertNotNil(form.getTextFieldElement(addressSpec.zipNameType.localizedLabel))
    }
}

extension PaymentSheet_LPM_ConfirmFlowTests: PaymentSheetAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return window.rootViewController!
    }

    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void) {
        // no-op
    }

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        completion?()
    }

    func presentPollingVCForAction(action: STPPaymentHandlerPaymentIntentActionParams, type: STPPaymentMethodType, safariViewController: SFSafariViewController?) {
        // Simulate that the intent transitioned to succeeded
        // If we don't update the status to succeeded, completing the action with .succeeded may fail due to invalid state
        action.paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: [type.identifier], status: .succeeded)
        action.complete(with: .succeeded, error: nil)
    }
}

extension PaymentSheet_LPM_ConfirmFlowTests: PaymentMethodFormViewControllerDelegate {
    nonisolated func didUpdate(_ viewController: StripePaymentSheet.PaymentMethodFormViewController) {
    }

    nonisolated func updateErrorLabel(for error: (any Error)?) {
    }
}

// MARK: - IntentConfirmParams

extension PaymentSheet_LPM_ConfirmFlowTests {
    func testIntentConfirmParamsEquatable() {
        let lhs = IntentConfirmParams(type: .stripe(.card))
        let rhs = IntentConfirmParams(type: .stripe(.card))
        // When lhs has an obscure difference w/ rhs...
        lhs.confirmPaymentMethodOptions.setSetupFutureUsageIfNecessary(true, paymentMethodType: .card, customer: .init(id: "", ephemeralKeySecret: ""))
        // ...they should not be equal
        XCTAssertNotEqual(lhs, rhs)
    }
}

extension IntentConfirmParams: Equatable {
    static public func == (lhs: StripePaymentSheet.IntentConfirmParams, rhs: StripePaymentSheet.IntentConfirmParams) -> Bool {
        // Hack to compare `paymentMethodParams` objects; consider them equal if their serialized versions are the same
        let lhsPaymentMethodParams = URLEncoder.queryString(from: STPFormEncoder.dictionary(forObject: lhs.paymentMethodParams))
        let rhsPaymentMethodParams = URLEncoder.queryString(from: STPFormEncoder.dictionary(forObject: rhs.paymentMethodParams))
        if lhsPaymentMethodParams != rhsPaymentMethodParams {
            print("Params not equal: \(lhsPaymentMethodParams) vs \(rhsPaymentMethodParams)")
            return false
        }
        if lhs.paymentMethodType != rhs.paymentMethodType {
            print("Payment method types not equal: \(lhs.paymentMethodType) vs \(rhs.paymentMethodType)")
            return false
        }

        let lhsConfirmPaymentMethodOptions = URLEncoder.queryString(from: STPFormEncoder.dictionary(forObject: lhs.confirmPaymentMethodOptions))
        let rhsConfirmPaymentMethodOptions = URLEncoder.queryString(from: STPFormEncoder.dictionary(forObject: rhs.confirmPaymentMethodOptions))
        if lhsConfirmPaymentMethodOptions != rhsConfirmPaymentMethodOptions {
            print("Confirm payment method options not equal: \(lhs.confirmPaymentMethodOptions) vs \(rhs.confirmPaymentMethodOptions)")
            return false
        }

        if lhs.saveForFutureUseCheckboxState != rhs.saveForFutureUseCheckboxState {
            print("Save for future use checkbox states not equal: \(lhs.saveForFutureUseCheckboxState) vs \(rhs.saveForFutureUseCheckboxState)")
            return false
        }

        if lhs.didDisplayMandate != rhs.didDisplayMandate {
            print("Did display mandate states not equal: \(lhs.didDisplayMandate) vs \(rhs.didDisplayMandate)")
            return false
        }

        if lhs.financialConnectionsLinkedBank != rhs.financialConnectionsLinkedBank {
            print("Financial connections linked banks not equal: \(lhs.financialConnectionsLinkedBank.debugDescription) vs \(rhs.financialConnectionsLinkedBank.debugDescription)")
            return false
        }

        if lhs.instantDebitsLinkedBank != rhs.instantDebitsLinkedBank {
            print("Instant debits linked banks not equal: \(lhs.instantDebitsLinkedBank.debugDescription) vs \(rhs.instantDebitsLinkedBank.debugDescription)")
            return false
        }

        // Sanity check to make sure when we add new properties, we check them here
        let mirror = Mirror(reflecting: lhs)
        let propertyCount = mirror.children.count
        XCTAssertEqual(propertyCount, 7)

        return true
    }
}
