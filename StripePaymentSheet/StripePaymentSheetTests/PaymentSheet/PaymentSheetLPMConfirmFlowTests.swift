//
//  PaymentSheet+LPMConfirmFlowTests.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 7/18/23.
//

import StripeCoreTestUtils
import XCTest

import SafariServices
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(ExternalPaymentMethodsPrivateBeta) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore

/// These tests exercise 9 different confirm flows based on the combination of:
/// - The Stripe Intent: PaymentIntent or PaymentIntent+SFU or SetupIntent
/// - The confirmation type: "Normal" intent-first client-side confirmation or "Deferred" client-side confirmation or "Deferred" server-side confirmation
/// They can also test the presence/absence of particular fields for a payment method form e.g. the SEPA test asserts that there's a mandate element.
/// 👀  See `testIdealConfirmFlows` for an example with comments.
@MainActor
final class PaymentSheet_LPM_ConfirmFlowTests: XCTestCase {

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
            }
        }
    }

    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
    }

    /// 👋 👨‍🏫  Look at this test to understand how to write your own tests in this file
    func testiDEALConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "EUR", paymentMethodType: .dynamic("ideal")) { form in
            // Fill out your payment method form in here.
            // Note: Each required field you fill out implicitly tests that the field exists; if the field doesn't exist, the test will fail because the form is incomplete.
            form.getTextFieldElement("Full name")?.setText("Foo")
            XCTAssertNotNil(form.getDropdownFieldElement("iDEAL Bank"))
            // You can also explicitly assert for the existence/absence of certain elements.
            // e.g. iDEAL shouldn't show a mandate or email field for a vanilla payment
            XCTAssertNil(form.getMandateElement())
            XCTAssertNil(form.getTextFieldElement("Email"))
            // Tip: To help you debug, print out `form.getAllUnwrappedSubElements()`
        }

        // If your payment method shows different fields depending on the kind of intent, you can call `_testConfirm` multiple times with different intents.
        // e.g. iDEAL should show an email field and mandate for PI+SFU and SIs, so we test those separately here:
        try await _testConfirm(intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .dynamic("ideal")) { form in
            form.getTextFieldElement("Full name")?.setText("Foo")
            form.getTextFieldElement("Email")?.setText("f@z.c")
            XCTAssertNotNil(form.getDropdownFieldElement("iDEAL Bank"))
            XCTAssertNotNil(form.getMandateElement())
        }
    }

    func testSEPADebitConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .dynamic("sepa_debit")) { form in
            form.getTextFieldElement("Full name")?.setText("Foo")
            form.getTextFieldElement("Email")?.setText("f@z.c")
            form.getTextFieldElement("IBAN")?.setText("DE89370400440532013000")
            form.getTextFieldElement("Address line 1")?.setText("asdf")
            form.getTextFieldElement("City")?.setText("asdf")
            form.getTextFieldElement("ZIP")?.setText("12345")
            XCTAssertNotNil(form.getMandateElement())
        }
    }

    func testAUBecsDebitConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent], currency: "AUD", paymentMethodType: .dynamic("au_becs_debit"), merchantCountry: .AU) { form in
            form.getTextFieldElement("Name on account")?.setText("Tester McTesterface")
            form.getTextFieldElement("Email")?.setText("example@link.com")
            form.getTextFieldElement("BSB number")?.setText("000000")
            form.getTextFieldElement("Account number")?.setText("000123456")
            XCTAssertNotNil(form.getAUBECSMandateElement())
        }
    }

    func testBancontactConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "EUR", paymentMethodType: .dynamic("bancontact")) { form in
            form.getTextFieldElement("Full name")?.setText("Foo")
            XCTAssertNil(form.getMandateElement())
            XCTAssertNil(form.getTextFieldElement("Email"))
        }

        try await _testConfirm(intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .dynamic("bancontact")) { form in
            form.getTextFieldElement("Full name")?.setText("Foo")
            form.getTextFieldElement("Email")?.setText("f@z.c")
            XCTAssertNotNil(form.getMandateElement())
        }
    }

    func testSofortConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "EUR", paymentMethodType: .dynamic("sofort")) { form in
            XCTAssertNotNil(form.getDropdownFieldElement("Country or region"))
            XCTAssertNil(form.getTextFieldElement("Full name"))
            XCTAssertNil(form.getTextFieldElement("Email"))
            XCTAssertNil(form.getMandateElement())
        }

        try await _testConfirm(intentKinds: [.paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .dynamic("sofort")) { form in
            XCTAssertNotNil(form.getDropdownFieldElement("Country or region"))
            form.getTextFieldElement("Full name")?.setText("Foo")
            form.getTextFieldElement("Email")?.setText("f@z.c")
            XCTAssertNotNil(form.getMandateElement())
        }
    }

    func testGrabPayConfirmFlows() async throws {
        // GrabPay has no input fields
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "SGD",
                               paymentMethodType: .dynamic("grabpay"),
                               merchantCountry: .SG) { _ in
        }
    }

    func testFPXConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "MYR",
                               paymentMethodType: .dynamic("fpx"),
                               merchantCountry: .MY) { form in
            XCTAssertNotNil(form.getDropdownFieldElement("FPX Bank"))
        }
    }

    func testBLIKConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent], currency: "PLN", paymentMethodType: .dynamic("blik"), merchantCountry: .BE) { form in
            form.getTextFieldElement("BLIK code")?.setText("123456")
        }
    }

    func testBacsDDConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage], currency: "GBP", paymentMethodType: .dynamic("bacs_debit"), merchantCountry: .GB) { form in
            form.getTextFieldElement("Full name")!.setText("Foo")
            form.getTextFieldElement("Email")!.setText("f@z.c")
            form.getTextFieldElement("Sort code")!.setText("108800")
            form.getTextFieldElement("Account number")!.setText("00012345")
            form.getTextFieldElement("Address line 1")!.setText("asdf")
            form.getTextFieldElement("City")!.setText("asdf")
            form.getTextFieldElement("ZIP")!.setText("12345")
            form.getCheckboxElement(startingWith: "I understand that Stripe will be collecting Direct Debits")!.isSelected = true
        }
    }

/* TODO: @lisaliu -- TODO: (9/15/2023) Uncomment this when amazon test mode becomes stable
    func testAmazonPayConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "USD",
                               paymentMethodType: .dynamic("amazon_pay"),
                               merchantCountry: .US) { form in
            // AmazonPay has no input fields
            XCTAssertEqual(form.getAllSubElements().count, 1)
        }
    }
*/
    func testAlmaConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "EUR",
                               paymentMethodType: .dynamic("alma"),
                               merchantCountry: .FR) { form in
            // Alma has no input fields
            XCTAssertEqual(form.getAllSubElements().count, 1)
        }
    }

    func testAlipayConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "USD",
                               paymentMethodType: .dynamic("alipay"),
                               merchantCountry: .US) { form in
            // Alipay has no input fields
            XCTAssertEqual(form.getAllSubElements().count, 1)
        }
    }

    func testOXXOConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "MXN",
                               paymentMethodType: .dynamic("oxxo"),
                               merchantCountry: .MX) { form in
            form.getTextFieldElement("Full name")?.setText("Jane Doe")
            form.getTextFieldElement("Email")?.setText("foo@bar.com")
        }
    }

    func testKonbiniConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "JPY",
                               paymentMethodType: .dynamic("konbini"),
                               merchantCountry: .JP) { form in
            form.getTextFieldElement("Full name")?.setText("Jane Doe")
            form.getTextFieldElement("Email")?.setText("foo@bar.com")
        }
    }

    func testPayNowConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "SGD",
                               paymentMethodType: .dynamic("paynow"),
                               merchantCountry: .SG) { form in
            // PayNow has no input fields
            XCTAssertEqual(form.getAllSubElements().count, 1)
        }
    }

    func testBoletoConfirmFlows() async throws {
        try await _testConfirm(
            intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent],
            currency: "BRL",
            paymentMethodType: .dynamic("boleto"),
            merchantCountry: .BR
        ) { form in
            form.getTextFieldElement("Full name")?.setText("Jane Doe")
            form.getTextFieldElement("Email")?.setText("foo@bar.com")
            form.getTextFieldElement("CPF/CPNJ")?.setText("00000000000")
            form.getTextFieldElement("Address line 1")?.setText("123 fake st")
            form.getTextFieldElement("City")?.setText("City")
            form.getTextFieldElement("State")?.setText("AC")  // Valid Brazilian state code
            form.getTextFieldElement("Postal code")?.setText("11111111")
        }
    }

    func testPromptPayConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent],
                               currency: "THB",
                               paymentMethodType: .dynamic("promptpay"),
                               merchantCountry: .TH) { form in
            form.getTextFieldElement("Email")?.setText("foo@bar.com")
        }
    }

    func testSwishConfirmFlows() async throws {
        try await _testConfirm(
            intentKinds: [.paymentIntent],
            currency: "SEK",
            paymentMethodType: .dynamic("swish"),
            merchantCountry: .FR
        ) { form in
            // Swish has no input fields
            XCTAssertEqual(form.getAllSubElements().count, 1)
        }
    }

    func testMobilePayConfirmFlows() async throws {
        try await _testConfirm(
            intentKinds: [.paymentIntent],
            currency: "DKK",
            paymentMethodType: .dynamic("mobilepay"),
            merchantCountry: .FR
        ) { form in
            // MobilePay has no input fields
            XCTAssertEqual(form.getAllSubElements().count, 1)
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

    func _testConfirm(intentKinds: [IntentKind], currency: String, paymentMethodType: PaymentSheet.PaymentMethodType, merchantCountry: MerchantCountry = .US, formCompleter: (PaymentMethodElement) -> Void) async throws {
        for intentKind in intentKinds {
            try await _testConfirm(intentKind: intentKind,
                                   currency: currency,
                                   paymentMethodType: paymentMethodType,
                                   merchantCountry: merchantCountry,
                                   formCompleter: formCompleter)
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
    func _testConfirm(intentKind: IntentKind,
                      currency: String,
                      paymentMethodType: PaymentSheet.PaymentMethodType,
                      merchantCountry: MerchantCountry = .US,
                      formCompleter: (PaymentMethodElement) -> Void) async throws {
        // Initialize PaymentSheet at least once to set the correct payment_user_agent for this process:
        let ic = PaymentSheet.IntentConfiguration(mode: .setup(), confirmHandler: { _, _, _ in })
        _ = PaymentSheet(mode: .deferredIntent(ic), configuration: PaymentSheet.Configuration())

        func makeDeferredIntent(_ intentConfig: PaymentSheet.IntentConfiguration) -> Intent {
            return .deferredIntent(elementsSession: ._testCardValue(), intentConfig: intentConfig)
        }
        let paymentMethodTypes = [PaymentSheet.PaymentMethodType.string(from: paymentMethodType)].compactMap { $0 }
        var intents: [(String, Intent)]
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

        // Update the API client based on the merchant country
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let configuration: PaymentSheet.Configuration = {
            var config = PaymentSheet.Configuration()
            config.apiClient = apiClient
            config.allowsDelayedPaymentMethods = true
            config.returnURL = "https://foo.com"
            config.allowsPaymentMethodsRequiringShippingAddress = true
            return config
        }()

        switch intentKind {
        case .paymentIntent:
            let paymentIntent: STPPaymentIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: paymentMethodTypes,
                                                                                           currency: currency,
                                                                                           merchantCountry: merchantCountry.rawValue)
                return try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }()

            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency)) { _, _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(types: paymentMethodTypes,
                                                                               currency: currency,
                                                                               merchantCountry: merchantCountry.rawValue)
            }

            intents = [
                ("PaymentIntent", .paymentIntent(paymentIntent)),
                ("Deferred PaymentIntent - client side confirmation", makeDeferredIntent(deferredCSC)),
            ]

            guard paymentMethodType != .dynamic("blik") else {
                // Blik doesn't support server-side confirmation
                break
            }

            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency)) { paymentMethod, _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(types: paymentMethodTypes, currency: currency,
                                                                               merchantCountry: merchantCountry.rawValue,
                                                                               paymentMethodID: paymentMethod.stripeId,
                                                                               confirm: true,
                                                                               otherParams: paramsForServerSideConfirmation)
            }

            intents += [
                ("Deferred PaymentIntent - server side confirmation", makeDeferredIntent(deferredSSC)),
            ]

        case .paymentIntentWithSetupFutureUsage:
            let paymentIntent: STPPaymentIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: paymentMethodTypes, currency: currency, merchantCountry: merchantCountry.rawValue, otherParams: ["setup_future_usage": "off_session"])
                return try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }()
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency, setupFutureUsage: .offSession)) { _, _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(types: paymentMethodTypes, currency: currency, merchantCountry: merchantCountry.rawValue, otherParams: ["setup_future_usage": "off_session"])
            }
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency, setupFutureUsage: .offSession)) { paymentMethod, _ in
                let otherParams = [
                    "setup_future_usage": "off_session",
                ].merging(paramsForServerSideConfirmation) { _, b in b }
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(types: paymentMethodTypes, currency: currency, merchantCountry: merchantCountry.rawValue, paymentMethodID: paymentMethod.stripeId, confirm: true, otherParams: otherParams)
            }
            intents = [
                ("PaymentIntent", .paymentIntent(paymentIntent)),
                ("Deferred PaymentIntent w/ setup_future_usage - client side confirmation", makeDeferredIntent(deferredCSC)),
                ("Deferred PaymentIntent w/ setup_future_usage - server side confirmation", makeDeferredIntent(deferredSSC)),
            ]
        case .setupIntent:
            let setupIntent: STPSetupIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes, merchantCountry: merchantCountry.rawValue)
                return try await apiClient.retrieveSetupIntent(clientSecret: clientSecret)
            }()
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { _, _ in
                return try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes, merchantCountry: merchantCountry.rawValue)
            }
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { paymentMethod, _ in
                return try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes, merchantCountry: merchantCountry.rawValue, paymentMethodID: paymentMethod.stripeId, confirm: true, otherParams: paramsForServerSideConfirmation)
            }
            intents = [
                ("SetupIntent", .setupIntent(setupIntent)),
                ("Deferred SetupIntent - client side confirmation", makeDeferredIntent(deferredCSC)),
                ("Deferred SetupIntent - server side confirmation", makeDeferredIntent(deferredSSC)),
            ]
        }
        for (description, intent) in intents {
            // Make the form
            let formFactory = PaymentSheetFormFactory(intent: intent, configuration: .paymentSheet(configuration), paymentMethod: paymentMethodType)
            let paymentMethodForm = formFactory.make()
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 1000))
            view.addAndPinSubview(paymentMethodForm.view)

            // Fill out the form
            sendEventToSubviews(.viewDidAppear, from: paymentMethodForm.view) // Simulate view appearance. This makes SimpleMandateElement mark its mandate as having been displayed.
            formCompleter(paymentMethodForm)

            // Generate params from the form
            guard let intentConfirmParams = paymentMethodForm.updateParams(params: IntentConfirmParams(type: paymentMethodType)) else {
                XCTFail("Form failed to create params. Validation state: \(paymentMethodForm.validationState)")
                return
            }
            let e = expectation(description: "Confirm")
            let paymentHandler = STPPaymentHandler(apiClient: apiClient, formSpecPaymentHandler: PaymentSheetFormSpecPaymentHandler())
            var redirectShimCalled = false
            paymentHandler._redirectShim = { _, _, _ in
                // This gets called instead of the PaymentSheet.confirm callback if the Intent is successfully confirmed and requires next actions.
                print("✅ \(description): Successfully confirmed the intent and saw a redirect attempt.")
                paymentHandler._handleWillForegroundNotification()
                redirectShimCalled = true
            }

            // Confirm the intent with the form details
            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: self,
                intent: intent,
                paymentOption: .new(confirmParams: intentConfirmParams),
                paymentHandler: paymentHandler
            ) { result, _  in
                switch result {
                case .failed(error: let error):
                    XCTFail("❌ \(description): PaymentSheet.confirm failed - \(error)")
                case .canceled:
                    XCTAssertTrue(redirectShimCalled, "❌ \(description): PaymentSheet.confirm canceled")
                case .completed:
                    print("✅ \(description): PaymentSheet.confirm completed")
                }
                e.fulfill()
            }
            await fulfillment(of: [e], timeout: 10)
        }
    }
}

extension PaymentSheet_LPM_ConfirmFlowTests: PaymentSheetAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }

    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void) {
        // no-op
    }

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        completion?()
    }

    func presentPollingVCForAction(action: STPPaymentHandlerActionParams, type: STPPaymentMethodType, safariViewController: SFSafariViewController?) {
        guard let currentAction = action as? STPPaymentHandlerPaymentIntentActionParams else { return }
        // Simulate that the intent transitioned to succeeded
        // If we don't update the status to succeeded, completing the action with .succeeded may fail due to invalid state
        currentAction.paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: [type.identifier], status: .succeeded)
        currentAction.complete(with: .succeeded, error: nil)
    }
}
