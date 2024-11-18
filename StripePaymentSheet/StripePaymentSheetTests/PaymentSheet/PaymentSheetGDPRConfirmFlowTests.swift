//
//  PaymentSheetGDPRConfirmFlowTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
import XCTest

import SafariServices
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(CustomerSessionBetaAccess) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore

@MainActor
final class PaymentSheet_GDPR_ConfirmFlowTests: STPNetworkStubbingTestCase {
    enum IntentKind: CaseIterable {
        case paymentIntent_intentFirst_csc
        case paymentIntent_deferredIntent_csc
        case paymentIntent_deferredIntent_ssc

        case paymentIntentSFU_intentFirst_csc
        case paymentIntentSFU_deferredIntent_csc
        case paymentIntentSFU_deferredIntent_ssc

        case setupIntent_intentFirst_csc
        case setupIntent_deferredIntent_csc
        case setupIntent_deferredIntent_ssc
    }

    enum CheckboxBehavior {
        case checked
        case unchecked
        case hidden
    }

    enum ExpectedAllowRedisplay {
        case attached(STPPaymentMethodAllowRedisplay)
        case unattached
    }

    enum MerchantCountry: String {
        case US = "us"
        var publishableKey: String {
            switch self {
            case .US:
                return STPTestingDefaultPublishableKey
            }
        }
    }

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

    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
        // Don't follow redirects for this specific tests, as we want to record
        // the body of the redirect request for UnredirectableSessionDelegate.
        self.followRedirects = false
    }

    func testAllowRedisplay_PI_IntentFirst() async throws {
        try await _testAndAssert(intentKind: .paymentIntent_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.always))

        try await _testAndAssert(intentKind: .paymentIntent_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .unattached)

        try await _testAndAssert(intentKind: .paymentIntent_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .unattached)
    }

    func testAllowRedisplay_PI_DeferredCSC() async throws {
        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.always))

        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .unattached)

        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .unattached)
    }

    func testAllowRedisplay_PI_deferredIntent_ssc() async throws {
        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .unattached)

        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: false),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .unattached)
    }

    func testAllowRedisplay_PISFU_intentFirst_csc() async throws {
        try await _testAndAssert(intentKind: .paymentIntentSFU_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .paymentIntentSFU_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .attached(.limited))

        try await _testAndAssert(intentKind: .paymentIntentSFU_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.limited))
    }

    func testAllowRedisplay_PISFU_deferredIntent_csc() async throws {
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .attached(.limited))

        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.limited))
    }

    func testAllowRedisplay_PISFU_deferredIntent_ssc() async throws {
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .attached(.limited))

        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: false),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.limited))

    }

    func testAllowRedisplay_SI_intentFirst_csc() async throws {
        try await _testAndAssert(intentKind: .setupIntent_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .setupIntent_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .attached(.limited))

        try await _testAndAssert(intentKind: .setupIntent_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.limited))
    }

    func testAllowRedisplay_SI_deferredIntent_csc() async throws {
        try await _testAndAssert(intentKind: .setupIntent_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .setupIntent_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .attached(.limited))

        try await _testAndAssert(intentKind: .setupIntent_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.limited))
    }

    func testAllowRedisplay_SI_deferredIntent_ssc() async throws {
        try await _testAndAssert(intentKind: .setupIntent_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .setupIntent_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: true),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .attached(.limited))

        try await _testAndAssert(intentKind: .setupIntent_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: false),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.limited))
    }

    func testAllowRedisplay_paymentIntent_legacyEphemeralKey() async throws {
        try await _testAndAssert(intentKind: .paymentIntent_intentFirst_csc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.unspecified))
        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_csc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.unspecified))
        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_ssc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .checked,
                                 expectedAllowRedisplay: .attached(.unspecified))

        try await _testAndAssert(intentKind: .paymentIntent_intentFirst_csc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .unattached)
        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_csc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .unattached)
        try await _testAndAssert(intentKind: .paymentIntent_deferredIntent_ssc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .unchecked,
                                 expectedAllowRedisplay: .unattached)
    }

    func testAllowRedisplay_paymentIntentSFU_legacyEphemeralKey() async throws {
        try await _testAndAssert(intentKind: .paymentIntentSFU_intentFirst_csc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.unspecified))
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_csc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.unspecified))
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_ssc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.unspecified))
    }

    func testAllowRedisplay_paymentIntentSI_legacyEphemeralKey() async throws {
        try await _testAndAssert(intentKind: .paymentIntentSFU_intentFirst_csc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.unspecified))
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_csc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.unspecified))
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_ssc,
                                 elementsSession: ._testCardValue(),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.unspecified))
    }

    func testAllowRedisplay_allowOverride() async throws {
        try await _testAndAssert(intentKind: .paymentIntentSFU_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false, allowRedisplayOverride: .always),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false, allowRedisplayOverride: .always),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .paymentIntentSFU_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false, allowRedisplayOverride: .always),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.always))

        try await _testAndAssert(intentKind: .setupIntent_intentFirst_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false, allowRedisplayOverride: .always),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .setupIntent_deferredIntent_csc,
                                 elementsSession: elementsSession(paymentMethodSave: false, allowRedisplayOverride: .always),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.always))
        try await _testAndAssert(intentKind: .setupIntent_deferredIntent_ssc,
                                 elementsSession: elementsSession(paymentMethodSave: false, allowRedisplayOverride: .always),
                                 checkbox: .hidden,
                                 expectedAllowRedisplay: .attached(.always))
    }

    func _testAndAssert(intentKind: IntentKind,
                        elementsSession: STPElementsSession,
                        paymentMethodTypes: [String] = ["card"],
                        currency: String = "USD",
                        merchantCountry: MerchantCountry = .US,
                        checkbox: CheckboxBehavior,
                        expectedAllowRedisplay: ExpectedAllowRedisplay) async throws {
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let newCustomer = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: nil,
                                                                                              merchantCountry: merchantCountry.rawValue.lowercased())
        let clientSecretResolved = expectation(description: "clientSecretResolved")
        var clientSecret: String!
        let intent = try await createIntent(intentKind: intentKind,
                                            apiClient: apiClient,
                                            customerID: newCustomer.customer,
                                            paymentMethodTypes: paymentMethodTypes,
                                            currency: currency,
                                            merchantCountry: merchantCountry) { cs in
            clientSecret = cs
            clientSecretResolved.fulfill()
        }
        try await _testConfirm(intent: intent,
                               elementsSession: elementsSession,
                               customerId: newCustomer.customer,
                               currency: currency,
                               apiClient: apiClient,
                               paymentMethodType: .stripe(.card),
                               merchantCountry: merchantCountry) { form in
            form.getTextFieldElement("Card number")?.setText("4242424242424242")
            form.getTextFieldElement("MM / YY").setText("1232")
            form.getTextFieldElement("CVC").setText("123")
            form.getTextFieldElement("ZIP").setText("65432")
            let saveCardForFuture = "Save payment details to"
            switch checkbox {
            case .checked:
                form.getCheckboxElement(startingWith: saveCardForFuture)!.isSelected = true
            case .unchecked:
                form.getCheckboxElement(startingWith: saveCardForFuture)!.isSelected = false
            case .hidden:
                XCTAssertNil(form.getCheckboxElement(startingWith: saveCardForFuture))
            }
        }
        await fulfillment(of: [clientSecretResolved])

        try await assertAllowRedisplayValue(apiClient: apiClient,
                                            intentKind: intentKind,
                                            confirmedPaymentIntentClientSecret: clientSecret,
                                            customerResponse: newCustomer,
                                            expectedAllowRedisplay: expectedAllowRedisplay)
    }

    @MainActor
    func _testConfirm(
        intent: Intent,
        elementsSession: STPElementsSession,
        customerId: String,
        currency: String,
        apiClient: STPAPIClient,
        paymentMethodType: PaymentSheet.PaymentMethodType,
        merchantCountry: MerchantCountry,
        formCompleter: (PaymentMethodElement) -> Void
    ) async throws {

        let configuration: PaymentSheet.Configuration = {
            var config = PaymentSheet.Configuration()
            config.returnURL = "https://foo.com"
            config.apiClient = apiClient
            config.customer = PaymentSheet.CustomerConfiguration(id: customerId, customerSessionClientSecret: "cuss_123")
            return config
        }()

        // Initialize PaymentSheet at least once to set the correct payment_user_agent for this process:
        let ic = PaymentSheet.IntentConfiguration(mode: .setup(), confirmHandler: { _, _, _ in })
        _ = PaymentSheet(mode: .deferredIntent(ic), configuration: PaymentSheet.Configuration())

        // Make the form
        let formFactory = PaymentSheetFormFactory(intent: intent, elementsSession: elementsSession, configuration: .paymentSheet(configuration), paymentMethod: paymentMethodType)
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
        let paymentHandler = STPPaymentHandler(apiClient: apiClient)
        var redirectShimCalled = false
        paymentHandler._redirectShim = { _, _, _ in
            // This gets called instead of the PaymentSheet.confirm callback if the Intent is successfully confirmed and requires next actions.
            print("✅ Successfully confirmed the intent and saw a redirect attempt.")
            paymentHandler._handleWillForegroundNotification()
            redirectShimCalled = true
        }

        // Confirm the intent with the form details
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: intent,
            elementsSession: elementsSession,
            paymentOption: .new(confirmParams: intentConfirmParams),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue()
        ) { result, _  in
            switch result {
            case .failed(error: let error):
                XCTFail("❌ PaymentSheet.confirm failed - \(error.nonGenericDescription)")
            case .canceled:
                XCTAssertTrue(redirectShimCalled, "❌ PaymentSheet.confirm canceled")
            case .completed:
                print("✅ PaymentSheet.confirm completed")
            }
            e.fulfill()
        }
        await fulfillment(of: [e], timeout: 25)
    }

    func assertAllowRedisplayValue(apiClient: STPAPIClient,
                                   intentKind: IntentKind,
                                   confirmedPaymentIntentClientSecret clientSecret: String,
                                   customerResponse: STPTestingAPIClient.CreateEphemeralKeyResponse,
                                   expectedAllowRedisplay: ExpectedAllowRedisplay) async throws {

        var confirmedPaymentMethodId: String
        switch intentKind {
        case .paymentIntent_intentFirst_csc, .paymentIntent_deferredIntent_csc, .paymentIntent_deferredIntent_ssc,
                .paymentIntentSFU_intentFirst_csc, .paymentIntentSFU_deferredIntent_csc, .paymentIntentSFU_deferredIntent_ssc:
            let updatedPaymentIntent = try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            guard let pmId = updatedPaymentIntent.paymentMethodId else {
                XCTFail("No payment method attached to confirmed Intent")
                return
            }
            confirmedPaymentMethodId = pmId
        case .setupIntent_intentFirst_csc, .setupIntent_deferredIntent_csc, .setupIntent_deferredIntent_ssc:
            let updatedSetupIntent = try await apiClient.retrieveSetupIntent(clientSecret: clientSecret)
            guard let pmId = updatedSetupIntent.paymentMethodID else {
                XCTFail("No payment method attached to confirmed Intent")
                return
            }
            confirmedPaymentMethodId = pmId
        }

        let expect = expectation(description: "Allow_redisplay value matches expected")
        apiClient.listPaymentMethods(forCustomer: customerResponse.customer,
                                     using: customerResponse.ephemeralKeySecret) { paymentMethods, error in
            guard error == nil else {
                XCTFail("Failed to fetch paymentMethods, error: \(String(describing: error))")
                return
            }
            switch expectedAllowRedisplay {
            case .attached(let expectedAllowRedisplayValue):
                guard let fetchedPaymentMethod = paymentMethods?.filter({ paymentMethod in
                    paymentMethod.stripeId == confirmedPaymentMethodId
                }).first else {
                    XCTFail("Failed to fetch paymentMethod: \(confirmedPaymentMethodId)")
                    return
                }
                XCTAssertEqual(fetchedPaymentMethod.allowRedisplay, expectedAllowRedisplayValue)
                expect.fulfill()
            case .unattached:
                // Assert payment method was not attached to user
                XCTAssertTrue(paymentMethods?.isEmpty ?? false)
                expect.fulfill()

            }
        }
        await fulfillment(of: [expect], timeout: 10)
    }
}

// MARK: - Creation Helpers
extension PaymentSheet_GDPR_ConfirmFlowTests {
    func elementsSession(paymentMethodSave: Bool,
                         allowRedisplayOverride: STPPaymentMethodAllowRedisplay? = nil) -> STPElementsSession {
        let paymentMethodSaveValue = paymentMethodSave ? "enabled" : "disabled"

        var features: [String: Any] = [
            "payment_method_save": paymentMethodSaveValue,
            "payment_method_remove": "enabled",
        ]
        if let allowRedisplayOverride {
            features["payment_method_save_allow_redisplay_override"] = allowRedisplayOverride.stringValue
        }

        return STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                             customerSessionData: [
                                                "mobile_payment_element": [
                                                    "enabled": true,
                                                    "features": features,
                                                ],
                                                "customer_sheet": [
                                                    "enabled": false
                                                ],
                                             ])
    }

    func createIntent(intentKind: IntentKind,
                      apiClient: STPAPIClient,
                      customerID: String,
                      paymentMethodTypes: [String],
                      currency: String,
                      merchantCountry: MerchantCountry,
                      clientSecretCallback: @escaping (String) -> Void ) async throws -> Intent {
        switch intentKind {
        // MARK: - Payment Intent
        case .paymentIntent_intentFirst_csc:
            let paymentIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customerID
                )
                clientSecretCallback(clientSecret)
                return try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }()
            return .paymentIntent(paymentIntent)
        case .paymentIntent_deferredIntent_csc:
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency)) { _, _ in
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customerID
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredCSC)
        case .paymentIntent_deferredIntent_ssc:
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency)) { paymentMethod, shouldSavePM in
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    merchantCountry: merchantCountry.rawValue,
                    paymentMethodID: paymentMethod.stripeId,
                    shouldSavePM: shouldSavePM,
                    customerID: customerID,
                    confirm: true,
                    otherParams: self.paramsForServerSideConfirmation
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredSSC)

        // MARK: - Payment Intent + SFU
        case .paymentIntentSFU_intentFirst_csc:
            let paymentIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customerID,
                    otherParams: ["setup_future_usage": "off_session"]
                )
                clientSecretCallback(clientSecret)
                return try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }()
            return .paymentIntent(paymentIntent)
        case .paymentIntentSFU_deferredIntent_csc:
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency, setupFutureUsage: .offSession)) { _, _ in
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customerID,
                    otherParams: ["setup_future_usage": "off_session"]
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredCSC)
        case .paymentIntentSFU_deferredIntent_ssc:
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency, setupFutureUsage: .offSession)) { paymentMethod, shouldSavePM in
                let otherParams = [
                    "setup_future_usage": "off_session",
                ].merging(self.paramsForServerSideConfirmation) { _, b in b }

                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    merchantCountry: merchantCountry.rawValue,
                    paymentMethodID: paymentMethod.stripeId,
                    shouldSavePM: shouldSavePM,
                    customerID: customerID,
                    confirm: true,
                    otherParams: otherParams
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredSSC)

        // MARK: - Setup Intent
        case .setupIntent_intentFirst_csc:
            let setupIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(
                    types: paymentMethodTypes,
                    merchantCountry: merchantCountry.rawValue,
                    customerID: customerID
                )
                clientSecretCallback(clientSecret)
                return try await apiClient.retrieveSetupIntent(clientSecret: clientSecret)
            }()
            return .setupIntent(setupIntent)
        case .setupIntent_deferredIntent_csc:
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { _, _ in
                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes,
                                                                                         merchantCountry: merchantCountry.rawValue,
                                                                                         customerID: customerID)
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredCSC)
        case .setupIntent_deferredIntent_ssc:
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { paymentMethod, _ in

                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes,
                                                                                         merchantCountry: merchantCountry.rawValue,
                                                                                         paymentMethodID: paymentMethod.stripeId,
                                                                                         customerID: customerID,
                                                                                         confirm: true,
                                                                                         otherParams: self.paramsForServerSideConfirmation)
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredSSC)
        }
    }
}

extension PaymentSheet_GDPR_ConfirmFlowTests: PaymentSheetAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
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
