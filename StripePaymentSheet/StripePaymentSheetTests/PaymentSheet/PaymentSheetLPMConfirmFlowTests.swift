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
@testable @_spi(STP) @_spi(CustomerSessionBetaAccess) @_spi(ConfirmationTokensPublicPreview) import StripePaymentSheet
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

    let fileManager = FileManager.default
    var fileNamesDictionary: [Endpoint: [String]] = [:]

    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
        // Don't follow redirects for this specific tests, as we want to record
        // the body of the redirect request for UnredirectableSessionDelegate.
        self.followRedirects = false
        self.fileNamesDictionary = [:]
    }

    func testSEPADebitConfirmFlows() async throws {
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "https://foo.com"
        configuration.allowsPaymentMethodsRequiringShippingAddress = true
        configuration.defaultBillingDetails = PaymentSheet.BillingDetails(
            address: PaymentSheet.Address(
                city: "South San Francisco",
                country: "US",
                line1: "354 Oyster Point Blvd",
                postalCode: "94080",
                state: "CA"
            )
        )

        try await _testConfirm(intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .SEPADebit, configuration: configuration) { form in
            form.getTextFieldElement("Full name").setText("Foo")
            form.getTextFieldElement("Email").setText("f@z.c")
            form.getTextFieldElement("IBAN").setText("DE89370400440532013000")

            // With default billing details, individual address fields should be shown and pre-populated
            XCTAssertEqual(form.getTextFieldElement("Address line 1")?.text, "354 Oyster Point Blvd")
            XCTAssertEqual(form.getTextFieldElement("City")?.text, "South San Francisco")
            XCTAssertEqual(form.getTextFieldElement("ZIP")?.text, "94080")

            XCTAssertNotNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 16)
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
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "https://foo.com"
        configuration.allowsPaymentMethodsRequiringShippingAddress = true
        configuration.defaultBillingDetails = PaymentSheet.BillingDetails(
            address: PaymentSheet.Address(
                city: "South San Francisco",
                country: "US",
                line1: "354 Oyster Point Blvd",
                postalCode: "94080",
                state: "CA"
            )
        )

        try await _testConfirm(intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage], currency: "GBP", paymentMethodType: .bacsDebit, merchantCountry: .GB, configuration: configuration) { form in
            form.getTextFieldElement("Full name").setText("Foo")
            form.getTextFieldElement("Email").setText("f@z.c")
            form.getTextFieldElement("Sort code").setText("108800")
            form.getTextFieldElement("Account number").setText("00012345")

            // With default billing details, individual address fields should be shown and pre-populated
            XCTAssertEqual(form.getTextFieldElement("Address line 1")?.text, "354 Oyster Point Blvd")
            XCTAssertEqual(form.getTextFieldElement("City")?.text, "South San Francisco")
            XCTAssertEqual(form.getTextFieldElement("ZIP")?.text, "94080")

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
        try await _testConfirm(intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent],
                               currency: "EUR",
                               paymentMethodType: .satispay,
                               merchantCountry: .IT) { form in
            XCTAssertNotNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 2)
        }
    }

    func testCryptoConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "USD",
                               paymentMethodType: .crypto,
                               merchantCountry: .US) { form in
            // Crypto has no input fields
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
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "https://foo.com"
        configuration.allowsPaymentMethodsRequiringShippingAddress = true
        configuration.defaultBillingDetails = PaymentSheet.BillingDetails(
            address: PaymentSheet.Address(
                city: "São Paulo",
                country: "BR",
                line1: "Rua das Flores, 123",
                postalCode: "01234567",
                state: "SP"
            )
        )

        try await _testConfirm(
            intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent],
            currency: "BRL",
            paymentMethodType: .boleto,
            merchantCountry: .BR,
            configuration: configuration,
            defaultCountry: "BR"
        ) { form in
            form.getTextFieldElement("Full name").setText("Jane Doe")
            form.getTextFieldElement("Email").setText("foo@bar.com")
            form.getTextFieldElement("CPF/CPNJ").setText("00000000000")

            // With default billing details, individual address fields should be shown and pre-populated
            XCTAssertEqual(form.getTextFieldElement("Address line 1")?.text, "Rua das Flores, 123")
            XCTAssertEqual(form.getTextFieldElement("City")?.text, "São Paulo")
            XCTAssertEqual(form.getTextFieldElement("State")?.text, "SP")
            XCTAssertEqual(form.getTextFieldElement("Postal code")?.text, "01234567")

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

    func testAfterpayConfirmFlows() async throws {
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "https://foo.com"
        configuration.allowsPaymentMethodsRequiringShippingAddress = true
        configuration.defaultBillingDetails = PaymentSheet.BillingDetails(
            address: PaymentSheet.Address(
                city: "South San Francisco",
                country: "US",
                line1: "354 Oyster Point Blvd",
                postalCode: "94080",
                state: "CA"
            )
        )

        try await _testConfirm(
            intentKinds: [.paymentIntent],
            currency: "USD",
            paymentMethodType: .afterpayClearpay,
            merchantCountry: .US,
            configuration: configuration
        ) { form in
            // Afterpay shows name, email, and full billing
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 15)
            form.getTextFieldElement("Full name").setText("Foo")
            form.getTextFieldElement("Email").setText("foo@bar.com")

            // With default billing details, individual address fields should be shown and pre-populated
            XCTAssertEqual(form.getTextFieldElement("Address line 1")?.text, "354 Oyster Point Blvd")
            XCTAssertEqual(form.getTextFieldElement("City")?.text, "South San Francisco")
            XCTAssertEqual(form.getTextFieldElement("ZIP")?.text, "94080")
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
        AnalyticsHelper.shared.generateSessionID()
        let customer = "cus_OaMPphpKbeixCz"  // A hardcoded customer on acct_1G6m1pFY0qyl6XeW
        let savedSepaPM = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_1NnBnhFY0qyl6XeW9ThDjAvw", // A hardcoded SEPA PM for the ^ customer
            "type": "sepa_debit",
        ])!

        // Update the API client based on the merchant country
        let apiClient = STPAPIClient(publishableKey: MerchantCountry.US.publishableKey)

        // Create customer session for confirmation token support
        let customerAndCustomerSession = try await STPTestingAPIClient.shared().fetchCustomerAndCustomerSessionClientSecret(
            customerID: customer,
            merchantCountry: "us",
            paymentMethodSave: true
        )

        let configuration: PaymentSheet.Configuration = {
            var config = PaymentSheet.Configuration()
            config.apiClient = apiClient
            config.allowsDelayedPaymentMethods = true
            config.returnURL = "https://foo.com"
            config.customer = PaymentSheet.CustomerConfiguration(
                id: customerAndCustomerSession.customer,
                customerSessionClientSecret: customerAndCustomerSession.customerSessionClientSecret
            )
            return config
        }()

        // Confirm saved SEPA with every confirm variation
        for intentKind in IntentKind.allCases {
            for (description, intent) in try await makeTestIntents(intentKind: intentKind, currency: "eur", paymentMethod: .SEPADebit, merchantCountry: .US, customer: customer, apiClient: apiClient) {

                // Create elements session with customer configuration for proper ephemeral keys
                let elementsSession: STPElementsSession
                switch intent {
                case .paymentIntent, .setupIntent:
                    // For regular intents, use test value
                    elementsSession = ._testValue(intent: intent)
                case .deferredIntent(let intentConfig):
                    // For deferred intents, create real elements session with customer config
                    elementsSession = try await apiClient.retrieveDeferredElementsSession(
                        withIntentConfig: intentConfig,
                        clientDefaultPaymentMethod: nil,
                        configuration: configuration
                    )
                }

                let e = expectation(description: "")
                // Confirm the intent with the form details
                let paymentHandler = STPPaymentHandler(apiClient: apiClient)
                PaymentSheet.confirm(
                    configuration: configuration,
                    authenticationContext: self,
                    intent: intent,
                    elementsSession: elementsSession,
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
                        if !self.recordingMode {
                            self.verifyClientAttributionMetadataInStubs(description: description, isNewPM: false)
                        }
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

    func testCardConfirmFlowsSetAsDefault() async throws {
        // Create a real customer with customer session
        let customer = "cus_OaMPphpKbeixCz"  // A hardcoded customer on acct_1G6m1pFY0qyl6XeW
        let merchantCountry = MerchantCountry.US
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)

        // Create customer session for confirmation token support
        let customerAndCustomerSession = try await STPTestingAPIClient.shared().fetchCustomerAndCustomerSessionClientSecret(
            customerID: customer,
            merchantCountry: merchantCountry.rawValue,
            paymentMethodSave: true
        )

        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient
        configuration.billingDetailsCollectionConfiguration.address = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.name = .never
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "https://foo.com"
        configuration.allowsPaymentMethodsRequiringShippingAddress = true
        configuration.customer = PaymentSheet.CustomerConfiguration(
            id: customerAndCustomerSession.customer,
            customerSessionClientSecret: customerAndCustomerSession.customerSessionClientSecret
        )
        try await _testConfirm(
            intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent],
            currency: "USD",
            paymentMethodType: .card,
            merchantCountry: merchantCountry,
            configuration: configuration,
            allowsSetAsDefaultPM: true
        ) { form in
            form.getCardSection().panElement.setText("4242424242424242")
            form.getCardSection().expiryElement.setText("1228")
            form.getCardSection().cvcElement.setText("123")
            form.getCheckboxElement(startingWith: "Save")?.isSelected = true
            form.getCheckboxElement(startingWith: "Set as default")?.isSelected = true
        }
    }

    func testEPSConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "EUR", paymentMethodType: .EPS) { form in
            form.getTextFieldElement("Full name").setText("John Doe")
            XCTAssertNil(form.getMandateElement())
            XCTAssertNil(form.getTextFieldElement("Email"))
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 5)
        }
    }

    func testPrzelewy24ConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "EUR", paymentMethodType: .przelewy24) { form in
            form.getTextFieldElement("Full name").setText("John Doe")
            form.getTextFieldElement("Email").setText("test@test.com")
            XCTAssertNotNil(form.getDropdownFieldElement("Przelewy24 Bank"))
            XCTAssertNil(form.getMandateElement())
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 7)
        }
    }

    func testAffirmConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "USD", paymentMethodType: .affirm, merchantCountry: .US) { form in
            // Affirm has no input fields and one non-interactive Affirm UI element
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 2)
        }
    }

    func testZipConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "AUD", paymentMethodType: .zip, merchantCountry: .AU) { form in
            // Zip has no input fields
            XCTAssertEqual(form.getAllUnwrappedSubElements().count, 1)
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
        allowsSetAsDefaultPM: Bool = false,
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
                allowsSetAsDefaultPM: allowsSetAsDefaultPM,
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
        allowsSetAsDefaultPM: Bool = false,
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

        let intents = try await makeTestIntents(intentKind: intentKind, currency: currency, amount: amount, paymentMethod: paymentMethodType, merchantCountry: merchantCountry, customer: configuration.customer?.id, apiClient: apiClient)

        // Check that the form respects billingDetailsCollection
        verifyFormRespectsBillingDetailsCollectionConfiguration(paymentMethodType: paymentMethodType, defaultCountry: defaultCountry)

        for (description, intent) in intents {

            func makeFormVC(previousCustomerInput: IntentConfirmParams?) -> PaymentMethodFormViewController {
                return PaymentMethodFormViewController(type: .stripe(paymentMethodType), intent: intent, elementsSession: ._testValue(intent: intent, allowsSetAsDefaultPM: allowsSetAsDefaultPM), previousCustomerInput: previousCustomerInput, formCache: .init(), configuration: configuration, headerView: nil, analyticsHelper: ._testValue(), delegate: self)
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
                    if self.recordingMode == false {
                        self.verifyClientAttributionMetadataInStubs(description: description)
                    }
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

        var intents: [(String, Intent)] = []
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

            // Confirmation token variations
            let deferredCSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .payment(amount: amount ?? 1099, currency: currency), paymentMethodTypes: [paymentMethod.identifier], confirmationTokenConfirmHandler: { _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customer
                )
            })

            let deferredSSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .payment(amount: amount ?? 1099, currency: currency), paymentMethodTypes: [paymentMethod.identifier], confirmationTokenConfirmHandler: { confirmationToken in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customer,
                    confirm: true,
                    otherParams: ["confirmation_token": confirmationToken.stripeId]
                )
            })

            intents += [
                ("Deferred PaymentIntent - client side confirmation with confirmation token", makeDeferredIntent(deferredCSCWithConfirmationToken)),
                ("Deferred PaymentIntent - server side confirmation with confirmation token", makeDeferredIntent(deferredSSCWithConfirmationToken)),
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
            // Confirmation token variations
            let deferredCSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .payment(amount: amount ?? 1099, currency: currency, setupFutureUsage: .offSession), paymentMethodTypes: [paymentMethod.identifier], confirmationTokenConfirmHandler: { _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customer
                )
            })

            let deferredSSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .payment(amount: amount ?? 1099, currency: currency, setupFutureUsage: .offSession), paymentMethodTypes: [paymentMethod.identifier], confirmationTokenConfirmHandler: { confirmationToken in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: amount,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customer,
                    confirm: true,
                    otherParams: [
                        "confirmation_token": confirmationToken.stripeId
                    ]
                )
            })

            return [

                ("Deferred PaymentIntent w/ setup_future_usage - client side confirmation with confirmation token", makeDeferredIntent(deferredCSCWithConfirmationToken)),
                ("Deferred PaymentIntent w/ setup_future_usage - server side confirmation with confirmation token", makeDeferredIntent(deferredSSCWithConfirmationToken)),
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
            // Confirmation token variations
            let deferredCSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession), paymentMethodTypes: [paymentMethod.identifier], confirmationTokenConfirmHandler: { _ in
                return try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes, merchantCountry: merchantCountry.rawValue, customerID: customer)
            })

            let deferredSSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession), paymentMethodTypes: [paymentMethod.identifier], confirmationTokenConfirmHandler: { confirmationToken in
                return try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes, merchantCountry: merchantCountry.rawValue, customerID: customer, confirm: true, otherParams: ["confirmation_token": confirmationToken.stripeId])
            })

            return [
                ("SetupIntent", .setupIntent(setupIntent)),
                ("Deferred SetupIntent - client side confirmation", makeDeferredIntent(deferredCSC)),
                ("Deferred SetupIntent - server side confirmation", makeDeferredIntent(deferredSSC)),
                ("Deferred SetupIntent - client side confirmation with confirmation token", makeDeferredIntent(deferredCSCWithConfirmationToken)),
                ("Deferred SetupIntent - server side confirmation with confirmation token", makeDeferredIntent(deferredSSCWithConfirmationToken)),
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
        var form = PaymentSheetFormFactory(intent: ._testPaymentIntent(paymentMethodTypes: [paymentMethodType]), elementsSession: .emptyElementsSession, configuration: .paymentElement(noFieldsConfig), paymentMethod: .stripe(paymentMethodType)).make()

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
        allFieldsConfig.defaultBillingDetails = PaymentSheet.BillingDetails(
            address: PaymentSheet.Address(
                city: "South San Francisco",
                country: "US",
                line1: "354 Oyster Point Blvd",
                postalCode: "94080",
                state: "CA"
            )
        )
        form = PaymentSheetFormFactory(intent: ._testPaymentIntent(paymentMethodTypes: [paymentMethodType]), elementsSession: .emptyElementsSession, configuration: .paymentElement(allFieldsConfig), paymentMethod: .stripe(paymentMethodType)).make()
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

// MARK: - CAM Verification Helper
extension PaymentSheet_LPM_ConfirmFlowTests {
    enum Endpoint: String, CaseIterable {
        case confirm
        case paymentMethods = "payment_methods"
        case confirmationTokens = "confirmation_tokens"
    }
    enum Nested: String {
        case paymentMethodData = "payment_method_data"
    }

    func verifyClientAttributionMetadataInStubs(description: String, isNewPM: Bool = true) {
        let testName = self.name
        let stubURL = getStubURL()
        if fileNamesDictionary.isEmpty {
            buildFileNamesDictionary(stubURL: getStubURL())
        }
        let nestedUnder: Nested? = isNewPM ? .paymentMethodData : nil
        if description == "PaymentIntent" || description == "SetupIntent" { // intent-first
            verifyClientAttributionMetadataInStubs(testName: testName, stubURL: stubURL, endpoint: .confirm, nestedUnder: nestedUnder)
        } else if description.contains("Deferred") {
            if description.contains("client side confirmation") {
                if description.contains("confirmation token") { // deferred csc with ct
                    verifyClientAttributionMetadataInStubs(testName: testName, stubURL: stubURL, endpoint: .confirmationTokens, nestedUnder: nestedUnder)
                    verifyClientAttributionMetadataInStubs(testName: testName, stubURL: stubURL, endpoint: .confirm)
                } else { // deferred csc
                    if isNewPM {
                        verifyClientAttributionMetadataInStubs(testName: testName, stubURL: stubURL, endpoint: .paymentMethods)
                    }
                    verifyClientAttributionMetadataInStubs(testName: testName, stubURL: stubURL, endpoint: .confirm)
                }
            }
            if description.contains("server side confirmation") {
                if description.contains("confirmation token") { // deferred ssc with ct
                    verifyClientAttributionMetadataInStubs(testName: testName, stubURL: stubURL, endpoint: .confirmationTokens, nestedUnder: nestedUnder)
                } else { // deferred ssc
                    if isNewPM {
                        verifyClientAttributionMetadataInStubs(testName: testName, stubURL: stubURL, endpoint: .paymentMethods)
                    }
                }
            }
        }
    }

    /// Verifies that client_attribution_metadata appears in recorded network stubs with expected values
    func verifyClientAttributionMetadataInStubs(
        testName: String,
        stubURL: URL,
        endpoint: Endpoint,
        nestedUnder: Nested? = nil
    ) {
        guard let fileNames = fileNamesDictionary[endpoint],
              let fileName = fileNames.first
        else {
            XCTFail("❌ Could not find the next .tail file to check for \(endpoint.rawValue)")
            return
        }
        fileNamesDictionary[endpoint]?.remove(fileName)
        let filePath = stubURL.appendingPathComponent(fileName)

        guard let fileContents = try? String(contentsOf: filePath, encoding: .utf8) else {
            XCTFail("❌ Could not read file: \(fileName)")
            return
        }

        // Find the X-Stripe-Mock-Request header line
        let lines = fileContents.components(separatedBy: .newlines)
        guard let mockRequestLine = lines.first(where: { $0.hasPrefix("X-Stripe-Mock-Request:") }) else {
            XCTFail("❌ Could not find X-Stripe-Mock-Request: \(fileName)")
            return
        }

        // Extract the request parameters
        let requestParams = mockRequestLine.replacingOccurrences(of: "X-Stripe-Mock-Request: ", with: "")

        // Check for client_attribution_metadata parameters
        let hasCAM = requestParams.contains("client_attribution_metadata")

        if hasCAM {
            // Verify expected values are present
            XCTAssertTrue(
                requestParams.contains("client_attribution_metadata\\[merchant_integration_source]=elements"),
                "❌ Missing or incorrect merchant_integration_source in \(fileName)"
            )
            XCTAssertTrue(
                requestParams.contains("client_attribution_metadata\\[merchant_integration_subtype]=mobile"),
                "❌ Missing or incorrect merchant_integration_subtype in \(fileName)"
            )

            // Verify other required fields exist (with regex patterns for dynamic values)
            XCTAssertTrue(
                requestParams.contains("client_attribution_metadata\\[client_session_id]="),
                "❌ Missing client_session_id in \(fileName)"
            )
            XCTAssertTrue(
                requestParams.contains("client_attribution_metadata\\[elements_session_config_id]="),
                "❌ Missing elements_session_config_id in \(fileName)"
            )
            XCTAssertTrue(
                requestParams.contains("client_attribution_metadata\\[merchant_integration_version]="),
                "❌ Missing merchant_integration_version in \(fileName)"
            )

            if let nestedString = nestedUnder?.rawValue {
                // Verify expected values are present
                XCTAssertTrue(
                    requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[merchant_integration_source]=elements"),
                    "❌ Missing or incorrect merchant_integration_source in \(fileName)"
                )
                XCTAssertTrue(
                    requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[merchant_integration_subtype]=mobile"),
                    "❌ Missing or incorrect merchant_integration_subtype in \(fileName)"
                )

                // Verify other required fields exist (with regex patterns for dynamic values)
                XCTAssertTrue(
                    requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[client_session_id]="),
                    "❌ Missing client_session_id in \(fileName)"
                )
                XCTAssertTrue(
                    requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[elements_session_config_id]="),
                    "❌ Missing elements_session_config_id in \(fileName)"
                )
                XCTAssertTrue(
                    requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[merchant_integration_version]="),
                    "❌ Missing merchant_integration_version in \(fileName)"
                )
            }

            print("✅ Verified client_attribution_metadata in \(fileName)")
        }
    }

    func buildFileNamesDictionary(stubURL: URL) {
        // Find all .tail files for this test
        guard let enumerator = fileManager.enumerator(atPath: stubURL.path) else {
            XCTFail("❌ Could not enumerate files at path: \(stubURL.path)")
            return
        }

        // Collect and sort fileNames alphabetically
        for case let fileName as String in enumerator {
            for endpoint in Endpoint.allCases {
                if fileName.hasSuffix("\(endpoint.rawValue).tail") {
                    var fileNames = fileNamesDictionary[endpoint] ?? []
                    fileNames.append(fileName)
                    fileNames.sort() // Sort alphabetically
                    fileNamesDictionary[endpoint] = fileNames
                }
            }
        }
    }

    func getStubURL() -> URL {
        let testName = self.name
        // The test name comes in format like "-[PaymentSheetGDPRConfirmFlowTests testAllowRedisplay_PI_IntentFirst]"
        // We need to extract just the test method name and remove underscores
        var testMethodName = testName.components(separatedBy: " ").last?
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]")) ?? testName

        // Remove underscores to match directory naming convention
        testMethodName = testMethodName.replacingOccurrences(of: "_", with: "")

        // Construct the path to the recorded network traffic directory
        let testClass = "PaymentSheetLPMConfirmFlowTests"

        // The stubs are stored in the source tree relative to the repository root
        let currentFile = #file
        let currentDir = URL(fileURLWithPath: currentFile).deletingLastPathComponent()

        // Navigate from test file to stripe-ios root, then to StripePayments/StripePaymentsTestUtils/Resources
        let baseURL = currentDir
            .deletingLastPathComponent() // up from PaymentSheet/
            .deletingLastPathComponent() // up from StripePaymentSheetTests/
            .deletingLastPathComponent() // up from StripePaymentSheet/ -> now at stripe-ios/
            .appendingPathComponent("StripePayments")
            .appendingPathComponent("StripePaymentsTestUtils")
            .appendingPathComponent("Resources")
            .appendingPathComponent("recorded_network_traffic")
            .appendingPathComponent(testClass)
            .appendingPathComponent(testMethodName)
        return baseURL
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
        XCTAssertEqual(propertyCount, 8)

        return true
    }
}
