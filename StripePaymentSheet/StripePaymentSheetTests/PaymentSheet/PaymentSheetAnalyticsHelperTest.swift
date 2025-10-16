//
//  PaymentSheetAnalyticsHelperTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 8/2/24.
//

@testable@_spi(STP) import StripeCore
@_spi(STP)@testable import StripeCoreTestUtils
@_spi(STP)@testable import StripePayments
@testable @_spi(STP) @_spi(CustomPaymentMethodsBeta) @_spi(SharedPaymentToken) import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import XCTest

final class PaymentSheetAnalyticsHelperTest: XCTestCase {
    let analyticsClient = STPTestingAnalyticsClient()

    @MainActor
    func testPaymentSheetAddsUsage() {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "usd"), confirmHandler: { _, _, _ in })

        // Clear product usage prior to testing PaymentSheet
        STPAnalyticsClient.sharedClient.productUsage = Set()
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.isEmpty)
        _ = PaymentSheet(intentConfiguration: intentConfig, configuration: PaymentSheet.Configuration())
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.contains("PaymentSheet"))

        // Clear product usage prior to testing PaymentSheet.FlowController
        STPAnalyticsClient.sharedClient.productUsage = Set()
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.isEmpty)
        PaymentSheet.FlowController.create(intentConfiguration: intentConfig, configuration: PaymentSheet.Configuration()) { _ in
        }
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.contains("PaymentSheet.FlowController"))

        // Clear product usage prior to testing EmbeddedPaymentElement
        STPAnalyticsClient.sharedClient.productUsage = Set()
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.isEmpty)
        let e = expectation(description: "callback")
        EmbeddedPaymentElement.create(intentConfiguration: intentConfig, configuration: EmbeddedPaymentElement.Configuration()) { _ in
            e.fulfill()
        }
        wait(for: [e], timeout: 1.0)
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.contains("EmbeddedPaymentElement"))
    }

    func testPaymentSheetAnalyticPayload() throws {
        // Ensure there is a sessionID
        AnalyticsHelper.shared.generateSessionID()

        // setup
        let analytic = PaymentSheetAnalytic(
            event: STPAnalyticEvent.mcInitCompleteApplePay,
            additionalParams: ["testKey": "testVal"]
        )
        let client = STPAnalyticsClient()
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        // test
        let payload = client.payload(from: analytic, apiClient: apiClient)

        // verify
        var expectedPayload: [String: Any] = ([
            "event": STPAnalyticEvent.mcInitCompleteApplePay.rawValue,
            "pay_var": "paymentsheet",
            "ocr_type": "none",
            "apple_pay_enabled": 1,
            "testKey": "testVal",
        ] as [String: Any])
        // Add common payload
        expectedPayload.merge(client.commonPayload(apiClient)) { a, _ in a }
        XCTAssertTrue((payload as NSDictionary).isEqual(to: expectedPayload))
    }

    func testPaymentSheetInit() {
        let testcases: [(integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape, isApplePayEnabled: Bool, isCustomerProvided: Bool, expected: String)] = [
            (integrationShape: .flowController, isApplePayEnabled: false, isCustomerProvided: false, expected: "mc_custom_init_default"),
            (integrationShape: .flowController, isApplePayEnabled: false, isCustomerProvided: true, expected: "mc_custom_init_customer"),
            (integrationShape: .flowController, isApplePayEnabled: true, isCustomerProvided: false, expected: "mc_custom_init_applepay"),
            (integrationShape: .flowController, isApplePayEnabled: true, isCustomerProvided: true, expected: "mc_custom_init_customer_applepay"),
            (integrationShape: .complete, isApplePayEnabled: false, isCustomerProvided: false, expected: "mc_complete_init_default"),
            (integrationShape: .complete, isApplePayEnabled: false, isCustomerProvided: true, expected: "mc_complete_init_customer"),
            (integrationShape: .complete, isApplePayEnabled: true, isCustomerProvided: false, expected: "mc_complete_init_applepay"),
            (integrationShape: .complete, isApplePayEnabled: true, isCustomerProvided: true, expected: "mc_complete_init_customer_applepay"),
            (integrationShape: .embedded, isApplePayEnabled: true, isCustomerProvided: true, expected: "mc_embedded_init"),
        ]
        for (integrationShape, isApplePayEnabled, isCustomerProvided, expected) in testcases {
            let sut = PaymentSheetAnalyticsHelper(
                integrationShape: integrationShape,
                configuration: makeConfig(
                    applePay: isApplePayEnabled ? .init(merchantId: "", merchantCountryCode: "") : nil,
                    customer: isCustomerProvided ? .init(id: "", ephemeralKeySecret: "") : nil,
                    integrationShape: integrationShape
                ),
                analyticsClient: analyticsClient
            )
            sut.logInitialized()
            guard let lastEvent = analyticsClient.events.last as? PaymentSheetAnalytic else {
                XCTFail("Failed to get last event")
                return
            }
            XCTAssertEqual(expected, lastEvent.event.rawValue)
            XCTAssertEqual(isApplePayEnabled, lastEvent.additionalParams[jsonDict: "mpe_config"]?["apple_pay_config"] as? Bool)
            XCTAssertEqual(isCustomerProvided, lastEvent.additionalParams[jsonDict: "mpe_config"]?["customer"] as? Bool)
            switch integrationShape {
            case .complete, .flowController, .linkController:
                XCTAssertEqual("automatic", lastEvent.additionalParams[jsonDict: "mpe_config"]?["payment_method_layout"] as? String)
            case .embedded:
                XCTAssertEqual("continue", lastEvent.additionalParams[jsonDict: "mpe_config"]?["form_sheet_action"] as? String)
                XCTAssertEqual(true, lastEvent.additionalParams[jsonDict: "mpe_config"]?["embedded_view_displays_mandate_text"] as? Bool)
            }
        }
    }

    func testLogLoadFailed() {
        let integrationShapes: [(PaymentSheetAnalyticsHelper.IntegrationShape, String)] = [
            (.complete, "paymentsheet"),
            (.embedded, "embedded"),
            (.flowController, "flowcontroller"),
        ]

        for (shape, shapeString) in integrationShapes {
            let sut = PaymentSheetAnalyticsHelper(integrationShape: shape, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)

            // Reset the analytics client for each iteration
            analyticsClient._testLogHistory.removeAll()

            // Load started -> failed
            sut.logLoadStarted()
            sut.logLoadFailed(error: NSError(domain: "domain", code: 1))

            XCTAssertEqual(analyticsClient._testLogHistory[0]["event"] as? String, "mc_load_started")
            XCTAssertEqual(analyticsClient._testLogHistory[0]["integration_shape"] as? String, shapeString)
            XCTAssertEqual(analyticsClient._testLogHistory[1]["event"] as? String, "mc_load_failed")
            XCTAssertLessThan(analyticsClient._testLogHistory[1]["duration"] as! Double, 1.0)
            XCTAssertEqual(analyticsClient._testLogHistory[1]["integration_shape"] as? String, shapeString)
        }
    }

    func testLogLoadSucceeded() {
        let integrationShapes: [(PaymentSheetAnalyticsHelper.IntegrationShape, String)] = [
            (.complete, "paymentsheet"),
            (.embedded, "embedded"),
            (.flowController, "flowcontroller"),
        ]

        for (shape, shapeString) in integrationShapes {
            let sut = PaymentSheetAnalyticsHelper(integrationShape: shape, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)

            // Reset the analytics client for each iteration
            analyticsClient._testLogHistory.removeAll()

            let testCardJSON = [
                "id": "pm_123card",
                "type": "card",
                "card": [
                    "last4": "4242",
                    "brand": "visa",
                    "fingerprint": "B8XXs2y2JsVBtB9f",
                    "networks": ["available": ["visa"]],
                    "exp_month": "01",
                    "exp_year": "2040",
                ],
            ] as [AnyHashable: Any]
            let testUSBankAccountJSON = [
                "id": "pm_123bank",
                "type": "us_bank_account",
                "us_bank_account": [
                    "account_holder_type": "individual",
                    "account_type": "checking",
                    "bank_name": "STRIPE TEST BANK",
                    "fingerprint": "ickfX9sbxIyAlbuh",
                    "last4": "6789",
                    "networks": [
                      "preferred": "ach",
                      "supported": [
                        "ach",
                      ],
                    ] as [String: Any],
                    "routing_number": "110000000",
                ] as [String: Any],
                "billing_details": [
                    "name": "Sam Stripe",
                    "email": "sam@stripe.com",
                ] as [String: Any],
            ] as [AnyHashable: Any]
            let elementsSession: STPElementsSession = ._testDefaultCardValue(defaultPaymentMethod: STPPaymentMethod._testCard().stripeId, paymentMethods: [testCardJSON, testUSBankAccountJSON])
            // Load started -> succeeded
            sut.logLoadStarted()
            sut.logLoadSucceeded(
                intent: ._testValue(),
                elementsSession: elementsSession,
                defaultPaymentMethod: .saved(paymentMethod: STPPaymentMethod._testCard()),
                orderedPaymentMethodTypes: [.stripe(.card), .stripe(.USBankAccount)]
            )

            XCTAssertEqual(analyticsClient._testLogHistory[0]["event"] as? String, "mc_load_started")
            XCTAssertEqual(analyticsClient._testLogHistory[0]["integration_shape"] as? String, shapeString)

            let loadSucceededPayload = analyticsClient._testLogHistory[1]
            XCTAssertEqual(loadSucceededPayload["event"] as? String, "mc_load_succeeded")
            XCTAssertLessThan(loadSucceededPayload["duration"] as! Double, 1.0)
            XCTAssertEqual(loadSucceededPayload["selected_lpm"] as? String, "card")
            XCTAssertEqual(loadSucceededPayload["intent_type"] as? String, "payment_intent")
            XCTAssertEqual(loadSucceededPayload["ordered_lpms"] as? String, "card,us_bank_account")
            XCTAssertEqual(loadSucceededPayload["integration_shape"] as? String, shapeString)
            XCTAssertEqual(loadSucceededPayload["set_as_default_enabled"] as? Bool, true)
            XCTAssertEqual(loadSucceededPayload["has_default_payment_method"] as? Bool, true)
            XCTAssertEqual(loadSucceededPayload["fc_sdk_availability"] as? String, "LITE")
            XCTAssertEqual(loadSucceededPayload["elements_session_config_id"] as? String, elementsSession.configID)
        }
    }

    func testLogSFU() {
        let sut = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)

        // Reset the analytics client for each iteration
        analyticsClient._testLogHistory.removeAll()

        let testCardJSON = [
            "id": "pm_123card",
            "type": "card",
            "card": [
                "last4": "4242",
                "brand": "visa",
                "fingerprint": "B8XXs2y2JsVBtB9f",
                "networks": ["available": ["visa"]],
                "exp_month": "01",
                "exp_year": "2040",
            ],
        ] as [AnyHashable: Any]
        let testUSBankAccountJSON = [
            "id": "pm_123bank",
            "type": "us_bank_account",
            "us_bank_account": [
                "account_holder_type": "individual",
                "account_type": "checking",
                "bank_name": "STRIPE TEST BANK",
                "fingerprint": "ickfX9sbxIyAlbuh",
                "last4": "6789",
                "networks": [
                  "preferred": "ach",
                  "supported": [
                    "ach",
                  ],
                ] as [String: Any],
                "routing_number": "110000000",
            ] as [String: Any],
            "billing_details": [
                "name": "Sam Stripe",
                "email": "sam@stripe.com",
            ] as [String: Any],
        ] as [AnyHashable: Any]
        // Load started -> succeeded
        sut.logLoadStarted()
        sut.logLoadSucceeded(
            intent: ._testPaymentIntent(
                paymentMethodTypes: [.card],
                setupFutureUsage: .offSession,
                paymentMethodOptionsSetupFutureUsage: [.card: "none"]
            ),
            elementsSession: ._testDefaultCardValue(defaultPaymentMethod: STPPaymentMethod._testCard().stripeId, paymentMethods: [testCardJSON, testUSBankAccountJSON]),
            defaultPaymentMethod: .saved(paymentMethod: STPPaymentMethod._testCard()),
            orderedPaymentMethodTypes: [.stripe(.card), .stripe(.USBankAccount)]
        )
        // PI with SFU and PMO SFU
        var loadSucceededPayload = analyticsClient._testLogHistory[1]
        XCTAssertEqual(loadSucceededPayload["event"] as? String, "mc_load_succeeded")
        XCTAssertEqual(loadSucceededPayload["setup_future_usage"] as? String, "off_session")
        XCTAssertEqual(loadSucceededPayload["payment_method_options_setup_future_usage"] as? Bool, true)
        analyticsClient._testLogHistory.removeAll()

        // Load started -> succeeded
        sut.logLoadStarted()
        sut.logLoadSucceeded(
            intent: ._testPaymentIntent(
                paymentMethodTypes: [.card],
                setupFutureUsage: .onSession
            ),
            elementsSession: ._testDefaultCardValue(defaultPaymentMethod: STPPaymentMethod._testCard().stripeId, paymentMethods: [testCardJSON, testUSBankAccountJSON]),
            defaultPaymentMethod: .saved(paymentMethod: STPPaymentMethod._testCard()),
            orderedPaymentMethodTypes: [.stripe(.card), .stripe(.USBankAccount)]
        )
        // PI with SFU and no PMO SFU
        loadSucceededPayload = analyticsClient._testLogHistory[1]
        XCTAssertEqual(loadSucceededPayload["event"] as? String, "mc_load_succeeded")
        XCTAssertEqual(loadSucceededPayload["setup_future_usage"] as? String, "on_session")
        XCTAssertEqual(loadSucceededPayload["payment_method_options_setup_future_usage"] as? Bool, false)
        analyticsClient._testLogHistory.removeAll()

        // Load started -> succeeded
        sut.logLoadStarted()
        sut.logLoadSucceeded(
            intent: ._testDeferredIntent(
                paymentMethodTypes: [.card],
                setupFutureUsage: .offSession,
                paymentMethodOptionsSetupFutureUsage: [.card: .onSession, .USBankAccount: .offSession]
            ),
            elementsSession: ._testDefaultCardValue(defaultPaymentMethod: STPPaymentMethod._testCard().stripeId, paymentMethods: [testCardJSON, testUSBankAccountJSON]),
            defaultPaymentMethod: .saved(paymentMethod: STPPaymentMethod._testCard()),
            orderedPaymentMethodTypes: [.stripe(.card), .stripe(.USBankAccount)]
        )
        // Deferred PI with SFU and PMO SFU
        loadSucceededPayload = analyticsClient._testLogHistory[1]
        XCTAssertEqual(loadSucceededPayload["event"] as? String, "mc_load_succeeded")
        XCTAssertEqual(loadSucceededPayload["setup_future_usage"] as? String, "off_session")
        XCTAssertEqual(loadSucceededPayload["payment_method_options_setup_future_usage"] as? Bool, true)
        analyticsClient._testLogHistory.removeAll()

        // Load started -> succeeded
        sut.logLoadStarted()
        sut.logLoadSucceeded(
            intent: ._testDeferredIntent(
                paymentMethodTypes: [.card],
                setupFutureUsage: .onSession
            ),
            elementsSession: ._testDefaultCardValue(defaultPaymentMethod: STPPaymentMethod._testCard().stripeId, paymentMethods: [testCardJSON, testUSBankAccountJSON]),
            defaultPaymentMethod: .saved(paymentMethod: STPPaymentMethod._testCard()),
            orderedPaymentMethodTypes: [.stripe(.card), .stripe(.USBankAccount)]
        )
        // Deferred PI with SFU and no PMO SFU
        loadSucceededPayload = analyticsClient._testLogHistory[1]
        XCTAssertEqual(loadSucceededPayload["event"] as? String, "mc_load_succeeded")
        XCTAssertEqual(loadSucceededPayload["setup_future_usage"] as? String, "on_session")
        XCTAssertEqual(loadSucceededPayload["payment_method_options_setup_future_usage"] as? Bool, false)
        analyticsClient._testLogHistory.removeAll()

        // Load started -> succeeded
        sut.logLoadStarted()
        sut.logLoadSucceeded(
            intent: ._testSetupIntent(),
            elementsSession: ._testDefaultCardValue(defaultPaymentMethod: STPPaymentMethod._testCard().stripeId, paymentMethods: [testCardJSON, testUSBankAccountJSON]),
            defaultPaymentMethod: .saved(paymentMethod: STPPaymentMethod._testCard()),
            orderedPaymentMethodTypes: [.stripe(.card), .stripe(.USBankAccount)]
        )
        // SI
        loadSucceededPayload = analyticsClient._testLogHistory[1]
        XCTAssertEqual(loadSucceededPayload["event"] as? String, "mc_load_succeeded")
        XCTAssertNil(loadSucceededPayload["setup_future_usage"])
        XCTAssertNil(loadSucceededPayload["payment_method_options_setup_future_usage"])
    }

    func testLogShow() {
        let paymentSheetHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
        paymentSheetHelper.logShow(showingSavedPMList: true)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_complete_sheet_savedpm_show")
        paymentSheetHelper.logShow(showingSavedPMList: false)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_complete_sheet_newpm_show")

        let flowControllerSUT = PaymentSheetAnalyticsHelper(integrationShape: .flowController, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
        flowControllerSUT.logShow(showingSavedPMList: true)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_custom_sheet_savedpm_show")
        flowControllerSUT.logShow(showingSavedPMList: false)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_custom_sheet_newpm_show")
    }

    func testLogRenderLPMs() {
        let paymentSheetHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
        paymentSheetHelper.logRenderLPMs(visibleLPMs: ["card", "paypal", "alma", "p24"], hiddenLPMs: ["eps"])
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_lpms_render")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["visible_lpms"] as? [String], ["card", "paypal", "alma", "p24"])
        XCTAssertEqual(analyticsClient._testLogHistory.last!["hidden_lpms"] as? [String], ["eps"])
    }

    func testLogSavedPMScreenOptionSelected() {
        func _createHelper(integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape) -> PaymentSheetAnalyticsHelper {
            let sut = PaymentSheetAnalyticsHelper(integrationShape: integrationShape, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
            return sut
        }
        let testcases: [(integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape, option: SavedPaymentOptionsViewController.Selection, expectedEvent: String, expectedSelectedLPM: String?)] = [
            (integrationShape: .complete, option: .applePay, expectedEvent: "mc_complete_paymentoption_applepay_select", nil),
            (integrationShape: .complete, option: .link, expectedEvent: "mc_complete_paymentoption_link_select", nil),
            (integrationShape: .complete, option: .add, expectedEvent: "mc_complete_paymentoption_newpm_select", nil),
            (integrationShape: .complete, option: .saved(paymentMethod: ._testCard()), expectedEvent: "mc_complete_paymentoption_savedpm_select", "card"),
            (integrationShape: .flowController, option: .applePay, expectedEvent: "mc_custom_paymentoption_applepay_select", nil),
            (integrationShape: .flowController, option: .link, expectedEvent: "mc_custom_paymentoption_link_select", nil),
            (integrationShape: .flowController, option: .add, expectedEvent: "mc_custom_paymentoption_newpm_select", nil),
            (integrationShape: .flowController, option: .saved(paymentMethod: ._testCard()), expectedEvent: "mc_custom_paymentoption_savedpm_select", "card"),
            (integrationShape: .embedded, option: .saved(paymentMethod: ._testCard()), expectedEvent: "mc_embedded_paymentoption_savedpm_select", "card"),

        ]
        for testcase in testcases {
            let sut = _createHelper(integrationShape: testcase.integrationShape)
            sut.logSavedPMScreenOptionSelected(option: testcase.option)
            XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, testcase.expectedEvent)
            if let expectedLpm = testcase.expectedSelectedLPM {
                XCTAssertEqual(analyticsClient._testLogHistory.last!["selected_lpm"] as? String, expectedLpm)
            }
        }
    }
    func testLogPaymentMethodRemoved() {
        let testcases: [(integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape, expectedEvent: String, expectedSelectedLPM: String)] = [
            (integrationShape: .flowController, expectedEvent: "mc_custom_paymentoption_removed", "card"),
            (integrationShape: .complete, expectedEvent: "mc_complete_paymentoption_removed", "card"),
            (integrationShape: .embedded, expectedEvent: "mc_embedded_paymentoption_removed", "card"),
        ]
        for testcase in testcases {
            let sut = PaymentSheetAnalyticsHelper(integrationShape: testcase.integrationShape, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
            sut.logSavedPaymentMethodRemoved(paymentMethod: ._testCard())
            XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, testcase.expectedEvent)
            XCTAssertEqual(analyticsClient._testLogHistory.last!["selected_lpm"] as? String, testcase.expectedSelectedLPM)
        }

    }
    func testLogNewPaymentMethodSelected() {
        let sut = PaymentSheetAnalyticsHelper(integrationShape: .flowController, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
        sut.logNewPaymentMethodSelected(paymentMethodTypeIdentifier: "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_carousel_payment_method_tapped")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["selected_lpm"] as? String, "card")
    }
    func testLogFormCompleted() {
        let sut = PaymentSheetAnalyticsHelper(integrationShape: .flowController, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
        sut.logFormShown(paymentMethodTypeIdentifier: "card")
        sut.logFormCompleted(paymentMethodTypeIdentifier: "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_form_completed")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["selected_lpm"] as? String, "card")
    }

    func testLogFormShownAndInteracted() {
        let sut = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
        sut.logFormShown(paymentMethodTypeIdentifier: "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_form_shown")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["selected_lpm"] as? String, "card")
        sut.logFormInteracted(paymentMethodTypeIdentifier: "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_form_interacted")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["selected_lpm"] as? String, "card")

        // Repeat form interacted calls should not log
        sut.logFormInteracted(paymentMethodTypeIdentifier: "card")
        sut.logFormInteracted(paymentMethodTypeIdentifier: "card")
        XCTAssertEqual(analyticsClient._testLogHistory.count, 2)
    }

    func testLogPayment() {
        let new = PaymentOption.new(confirmParams: .init(type: .stripe(.cashApp)))
        let saved = PaymentOption.saved(paymentMethod: ._testCard(), confirmParams: nil)
        let error = NSError(domain: "domain", code: 123)
        let testcases: [(integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape, paymentOption: PaymentOption, result: PaymentSheetResult, expected: String)] = [
            (integrationShape: .flowController, paymentOption: new, result: .completed, expected: "mc_custom_payment_newpm_success"),
            (integrationShape: .flowController, paymentOption: saved, result: .completed, expected: "mc_custom_payment_savedpm_success"),
            (integrationShape: .flowController, paymentOption: .applePay, result: .completed, expected: "mc_custom_payment_applepay_success"),
            (integrationShape: .flowController, paymentOption: .link(option: .wallet), result: .completed, expected: "mc_custom_payment_link_success"),
            (integrationShape: .flowController, paymentOption: .new(confirmParams: .init(type: .stripe(.cashApp))), result: .failed(error: error), expected: "mc_custom_payment_newpm_failure"),
            (integrationShape: .flowController, paymentOption: saved, result: .failed(error: error), expected: "mc_custom_payment_savedpm_failure"),
            (integrationShape: .flowController, paymentOption: .applePay, result: .failed(error: error), expected: "mc_custom_payment_applepay_failure"),
            (integrationShape: .flowController, paymentOption: .link(option: .wallet), result: .failed(error: error), expected: "mc_custom_payment_link_failure"),

            (integrationShape: .complete, paymentOption: new, result: .completed, expected: "mc_complete_payment_newpm_success"),
            (integrationShape: .complete, paymentOption: saved, result: .completed, expected: "mc_complete_payment_savedpm_success"),
            (integrationShape: .complete, paymentOption: .applePay, result: .completed, expected: "mc_complete_payment_applepay_success"),
            (integrationShape: .complete, paymentOption: .link(option: .wallet), result: .completed, expected: "mc_complete_payment_link_success"),
            (integrationShape: .complete, paymentOption: .new(confirmParams: .init(type: .stripe(.cashApp))), result: .failed(error: error), expected: "mc_complete_payment_newpm_failure"),
            (integrationShape: .complete, paymentOption: saved, result: .failed(error: error), expected: "mc_complete_payment_savedpm_failure"),
            (integrationShape: .complete, paymentOption: .applePay, result: .failed(error: error), expected: "mc_complete_payment_applepay_failure"),
            (integrationShape: .complete, paymentOption: .link(option: .wallet), result: .failed(error: error), expected: "mc_complete_payment_link_failure"),

            (integrationShape: .embedded, paymentOption: new, result: .completed, expected: "mc_embedded_payment_success"),
            (integrationShape: .embedded, paymentOption: saved, result: .completed, expected: "mc_embedded_payment_success"),
            (integrationShape: .embedded, paymentOption: .applePay, result: .completed, expected: "mc_embedded_payment_success"),
            (integrationShape: .embedded, paymentOption: .link(option: .wallet), result: .completed, expected: "mc_embedded_payment_success"),

            (integrationShape: .embedded, paymentOption: .new(confirmParams: .init(type: .stripe(.cashApp))), result: .failed(error: error), expected: "mc_embedded_payment_failure"),
            (integrationShape: .embedded, paymentOption: saved, result: .failed(error: error), expected: "mc_embedded_payment_failure"),
            (integrationShape: .embedded, paymentOption: .applePay, result: .failed(error: error), expected: "mc_embedded_payment_failure"),
            (integrationShape: .embedded, paymentOption: .link(option: .wallet), result: .failed(error: error), expected: "mc_embedded_payment_failure"),

        ]

        let cpms: [PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod] = [.init(id: "cpmt_123"), .init(id: "cpmt_789")]
        let cpmConfig = PaymentSheet.CustomPaymentMethodConfiguration(customPaymentMethods: cpms) { _, _ in
            return .canceled
        }

        for (integrationShape, paymentOption, result, expected) in testcases {
            var config = PaymentSheet.Configuration()
            config.customPaymentMethodConfiguration = cpmConfig

            let sut = PaymentSheetAnalyticsHelper(
                integrationShape: integrationShape,
                configuration: config,
                analyticsClient: analyticsClient
            )
            sut.intent = ._testValue()
            sut.elementsSession = ._testValue(paymentMethodTypes: ["card"], externalPaymentMethodTypes: [], linkMode: .linkCardBrand, linkFundingSources: [.card], linkUseAttestation: true, linkSuppress2FA: true)
            sut.logPayment(
                paymentOption: paymentOption,
                result: result,
                deferredIntentConfirmationType: nil
            )
            XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, expected)
            if case .failed = result {
                XCTAssertEqual(analyticsClient._testLogHistory.last!["error_type"] as? String, "domain")
                XCTAssertEqual(analyticsClient._testLogHistory.last!["error_code"] as? String, "123")
            }
            XCTAssertNil(analyticsClient._testLogHistory.last!["deferred_intent_confirmation_type"])
            XCTAssertEqual(analyticsClient._testLogHistory.last!["selected_lpm"] as? String, paymentOption.paymentMethodTypeAnalyticsValue)
            XCTAssertEqual(analyticsClient._testLogHistory.last!["link_context"] as? String, paymentOption.linkContextAnalyticsValue)
            XCTAssertEqual(analyticsClient._testLogHistory.last!["link_ui"] as? String, paymentOption.linkUIAnalyticsValue)
            XCTAssertEqual(analyticsClient._testLogHistory.last!["link_use_attestation"] as? Bool, false)
            XCTAssertEqual(analyticsClient._testLogHistory.last!["link_mobile_suppress_2fa_modal"] as? Bool, true)
            let mpeConfig = analyticsClient._testLogHistory.last!["mpe_config"] as! [String: Any]
            XCTAssertEqual(mpeConfig["custom_payment_methods"] as? [String], ["cpmt_123", "cpmt_789"])
        }
    }

    func testLogPaymentSendsDeferredIntentConfirmationType() {
        // Check deferred_intent_confirmation_type gets sent
        let sut = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: analyticsClient
        )
        sut.logLoadStarted()
        sut.logLoadSucceeded(
            intent: ._testDeferredIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            defaultPaymentMethod: nil,
            orderedPaymentMethodTypes: [.stripe(.card)]
        )
        sut.logPayment(
            paymentOption: .applePay,
            result: .completed,
            deferredIntentConfirmationType: .client
        )
        XCTAssertEqual(analyticsClient._testLogHistory.last!["deferred_intent_confirmation_type"] as? String, "client")
    }

    func testLogConfirmButtonTapped() {
        let sut = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
        sut.logFormShown(paymentMethodTypeIdentifier: "card")
        sut.logConfirmButtonTapped(paymentOption: .applePay)

        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_confirm_button_tapped")
        XCTAssertLessThan(analyticsClient._testLogHistory.last!["duration"] as! Double, 1.0)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["selected_lpm"] as? String, "apple_pay")

        sut.logConfirmButtonTapped(paymentOption: .link(option: .wallet))
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_confirm_button_tapped")
        XCTAssertLessThan(analyticsClient._testLogHistory.last!["duration"] as! Double, 1.0)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["selected_lpm"] as? String, "link")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["link_context"] as? String, "wallet")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["fc_sdk_availability"] as? String, "LITE")
    }

    func testLogPaymentLinkContextWithLinkedBank() {
        let instantDebitsLinkedBank = InstantDebitsLinkedBank(
            paymentMethod: LinkBankPaymentMethod(id: "paymentMethodId"),
            bankName: nil,
            last4: nil,
            linkMode: .linkPaymentMethod,
            incentiveEligible: false,
            linkAccountSessionId: "fcsess_"
        )
        let linkCardBrandLinkedBank = InstantDebitsLinkedBank(
            paymentMethod: LinkBankPaymentMethod(id: "paymentMethodId"),
            bankName: nil,
            last4: nil,
            linkMode: .linkCardBrand,
            incentiveEligible: false,
            linkAccountSessionId: "fcsess_"
        )

        let instantDebitConfirmParams = IntentConfirmParams(type: .instantDebits)
        instantDebitConfirmParams.instantDebitsLinkedBank = instantDebitsLinkedBank

        let linkCardBrandConfirmParams = IntentConfirmParams(type: .linkCardBrand)
        linkCardBrandConfirmParams.instantDebitsLinkedBank = linkCardBrandLinkedBank

        let instantDebits = PaymentOption.new(confirmParams: instantDebitConfirmParams)
        let linkCardBrand = PaymentOption.new(confirmParams: linkCardBrandConfirmParams)

        let sut = PaymentSheetAnalyticsHelper(
            integrationShape: .flowController,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: analyticsClient
        )
        sut.intent = ._testValue()

        sut.logPayment(
            paymentOption: instantDebits,
            result: .completed,
            deferredIntentConfirmationType: nil
        )
        XCTAssertEqual(analyticsClient._testLogHistory.last!["link_context"] as? String, "instant_debits")

        sut.logPayment(
            paymentOption: linkCardBrand,
            result: .completed,
            deferredIntentConfirmationType: nil
        )
        XCTAssertEqual(analyticsClient._testLogHistory.last!["link_context"] as? String, "link_card_brand")
    }

    func testLogEmbeddedUpdate() {
        let sut = PaymentSheetAnalyticsHelper(integrationShape: .embedded, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
        let testDuration: TimeInterval = 10.5

        // Test update started
        sut.logEmbeddedUpdateStarted()
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_embedded_update_started")

        // Test successful update
        sut.logEmbeddedUpdateFinished(result: .succeeded, duration: testDuration)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_embedded_update_finished")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["status"] as? String, "succeeded")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["duration"] as? TimeInterval, testDuration)
        XCTAssertNil(analyticsClient._testLogHistory.last!["error_type"])
        XCTAssertNil(analyticsClient._testLogHistory.last!["error_code"])

        // Test failed update
        sut.logEmbeddedUpdateStarted()
        let error = NSError(domain: "test", code: 123)
        sut.logEmbeddedUpdateFinished(result: .failed(error: error), duration: testDuration)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_embedded_update_finished")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["status"] as? String, "failed")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["duration"] as? TimeInterval, testDuration)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["error_type"] as? String, "test")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["error_code"] as? String, "123")

        // Test canceled update
        sut.logEmbeddedUpdateStarted()
        sut.logEmbeddedUpdateFinished(result: .canceled, duration: testDuration)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_embedded_update_finished")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["status"] as? String, "canceled")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["duration"] as? TimeInterval, testDuration)
        XCTAssertNil(analyticsClient._testLogHistory.last!["error_type"])
        XCTAssertNil(analyticsClient._testLogHistory.last!["error_code"])
    }

    func testAnalyticsIntentConfigurationParameters() {
        let sut = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: analyticsClient
        )
        sut.logLoadStarted() // To get the load timer working

        // Test case 1: Regular PaymentIntent (no intentConfig)
        // Should set is_decoupled = false, is_spt = false
        analyticsClient._testLogHistory.removeAll()
        let regularIntent = Intent._testValue()
        sut.logLoadSucceeded(
            intent: regularIntent,
            elementsSession: ._testValue(),
            defaultPaymentMethod: nil,
            orderedPaymentMethodTypes: [.stripe(.card)]
        )

        let regularEvent = analyticsClient._testLogHistory.last!
        XCTAssertEqual(regularEvent["is_decoupled"] as? Bool, false, "Regular PaymentIntent should have is_decoupled = false")
        XCTAssertEqual(regularEvent["is_spt"] as? Bool, false, "Regular PaymentIntent should have is_spt = false")

        // Test case 2: Deferred intent without preparePaymentMethodHandler
        // Should set is_decoupled = true, is_spt = false
        analyticsClient._testLogHistory.removeAll()
        let deferredIntentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "usd")) { _, _, _ in }
        let deferredIntent = Intent.deferredIntent(intentConfig: deferredIntentConfig)
        sut.logLoadSucceeded(
            intent: deferredIntent,
            elementsSession: ._testValue(),
            defaultPaymentMethod: nil,
            orderedPaymentMethodTypes: [.stripe(.card)]
        )

        let deferredEvent = analyticsClient._testLogHistory.last!
        XCTAssertEqual(deferredEvent["is_decoupled"] as? Bool, true, "Deferred intent should have is_decoupled = true")
        XCTAssertEqual(deferredEvent["is_spt"] as? Bool, false, "Deferred intent without preparePaymentMethodHandler should have is_spt = false")

        // Test case 3: Deferred intent with preparePaymentMethodHandler (SPT)
        // Should set is_decoupled = true, is_spt = true
        analyticsClient._testLogHistory.removeAll()
        let sptIntentConfig = PaymentSheet.IntentConfiguration(
            sharedPaymentTokenSessionWithMode: .payment(amount: 1000, currency: "usd"),
            sellerDetails: PaymentSheet.IntentConfiguration.SellerDetails(networkId: "stripe", externalId: "test", businessName: "Till's Pills"),
            paymentMethodTypes: ["card"],
            preparePaymentMethodHandler: { _, _ in
                // Empty handler for test
            }
        )
        let sptIntent = Intent.deferredIntent(intentConfig: sptIntentConfig)
        sut.logLoadSucceeded(
            intent: sptIntent,
            elementsSession: ._testValue(),
            defaultPaymentMethod: nil,
            orderedPaymentMethodTypes: [.stripe(.card)]
        )

        let sptEvent = analyticsClient._testLogHistory.last!
        XCTAssertEqual(sptEvent["is_decoupled"] as? Bool, true, "SPT intent should have is_decoupled = true")
        XCTAssertEqual(sptEvent["is_spt"] as? Bool, true, "SPT intent with preparePaymentMethodHandler should have is_spt = true")
    }

    // MARK: - Helpers

    func makeConfig(
        applePay: PaymentSheet.ApplePayConfiguration?,
        customer: PaymentSheet.CustomerConfiguration?,
        integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape
    ) -> PaymentElementConfiguration {
        switch integrationShape {
        case .flowController, .complete, .linkController:
            var config = PaymentSheet.Configuration()
            config.applePay = applePay
            config.customer = customer
            return config
        case .embedded:
            var config = EmbeddedPaymentElement.Configuration()
            config.applePay = applePay
            config.customer = customer
            return config
        }
    }
}

@inlinable func XCTAssertEqual(_ a: [String: Any], _ b: [String: Any]) {
   XCTAssertEqual(a as NSDictionary, b as NSDictionary)
}

extension Dictionary where Key == String, Value == Any {
    func removing(_ otherDict: [String: Any]) -> Dictionary {
        var updatedDict: [String: Any] = [:]
        for (key, value) in self {
            if !otherDict.keys.contains(key) {
                updatedDict[key] = value
            }
        }
        return updatedDict
    }
}

extension STPAnalyticsClient {
    var _testLogHistoryWithoutCommonPayload: [[String: Any]] {
        return _testLogHistory.map { $0.removing(commonPayload(.shared)) }
    }
}
