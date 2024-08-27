//
//  PaymentSheetAnalyticsHelperTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 8/2/24.
//

@testable@_spi(STP) import StripeCore
@_spi(STP)@testable import StripeCoreTestUtils
@testable@_spi(STP) import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import XCTest

final class PaymentSheetAnalyticsHelperTest: XCTestCase {
    let analyticsClient = STPTestingAnalyticsClient()

    func testPaymentSheetAddsUsage() {
        _ = PaymentSheet(
            paymentIntentClientSecret: "",
            configuration: PaymentSheet.Configuration()
        )
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.contains("PaymentSheet"))

        _ = PaymentSheet.FlowController(
            configuration: PaymentSheet.Configuration(),
            loadResult: .init(
                intent: .paymentIntent(STPFixtures.paymentIntent()),
                elementsSession: .makeBackupElementsSession(with: STPFixtures.paymentIntent()),
                savedPaymentMethods: []
            ), analyticsHelper: .init(isCustom: true, configuration: .init())
        )
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.contains("PaymentSheet.FlowController"))
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
        let testcases: [(isCustom: Bool, isApplePayEnabled: Bool, isCustomerProvided: Bool, expected: String)] = [
            (isCustom: true, isApplePayEnabled: false, isCustomerProvided: false, expected: "mc_custom_init_default"),
            (isCustom: true, isApplePayEnabled: false, isCustomerProvided: true, expected: "mc_custom_init_customer"),
            (isCustom: true, isApplePayEnabled: true, isCustomerProvided: false, expected: "mc_custom_init_applepay"),
            (isCustom: true, isApplePayEnabled: true, isCustomerProvided: true, expected: "mc_custom_init_customer_applepay"),
            (isCustom: false, isApplePayEnabled: false, isCustomerProvided: false, expected: "mc_complete_init_default"),
            (isCustom: false, isApplePayEnabled: false, isCustomerProvided: true, expected: "mc_complete_init_customer"),
            (isCustom: false, isApplePayEnabled: true, isCustomerProvided: false, expected: "mc_complete_init_applepay"),
            (isCustom: false, isApplePayEnabled: true, isCustomerProvided: true, expected: "mc_complete_init_customer_applepay"),
        ]
        for (isCustom, isApplePayEnabled, isCustomerProvided, expected) in testcases {
            let sut = PaymentSheetAnalyticsHelper(
                isCustom: isCustom,
                configuration: makeConfig(
                    applePay: isApplePayEnabled ? .init(merchantId: "", merchantCountryCode: "") : nil,
                    customer: isCustomerProvided ? .init(id: "", ephemeralKeySecret: "") : nil
                ),
                analyticsClient: analyticsClient
            )
            sut.logInitialized()
            XCTAssertEqual(expected, analyticsClient.events.last?.event.rawValue)
        }
    }

    func testLogLoadFailed() {
        let sut = PaymentSheetAnalyticsHelper(isCustom: false, configuration: .init(), analyticsClient: analyticsClient)
        // Load started -> failed
        sut.logLoadStarted()
        sut.logLoadFailed(error: NSError(domain: "domain", code: 1))
        XCTAssertEqual(analyticsClient._testLogHistory[0]["event"] as? String, "mc_load_started")
        XCTAssertEqual(analyticsClient._testLogHistory[1]["event"] as? String, "mc_load_failed")
        XCTAssertLessThan(analyticsClient._testLogHistory[1]["duration"] as! Double, 1.0)
    }

    func testLogLoadSucceeded() {
        let sut = PaymentSheetAnalyticsHelper(isCustom: false, configuration: .init(), analyticsClient: analyticsClient)
        // Load started -> succeeded
        sut.logLoadStarted()
        sut.logLoadSucceeded(
            intent: ._testValue(),
            elementsSession: ._testCardValue(),
            defaultPaymentMethod: .applePay,
            orderedPaymentMethodTypes: [.stripe(.card), .external(._testPayPalValue())]
        )
        XCTAssertEqual(analyticsClient._testLogHistory[0]["event"] as? String, "mc_load_started")

        let loadSucceededPayload = analyticsClient._testLogHistory[1]
        XCTAssertEqual(loadSucceededPayload["event"] as? String, "mc_load_succeeded")
        XCTAssertLessThan(loadSucceededPayload["duration"] as! Double, 1.0)
        XCTAssertEqual(loadSucceededPayload["selected_lpm"] as? String, "apple_pay")
        XCTAssertEqual(loadSucceededPayload["intent_type"] as? String, "payment_intent")
        XCTAssertEqual(loadSucceededPayload["ordered_lpms"] as? String, "card,external_paypal")
    }

    func testLogShow() {
        let paymentSheetHelper = PaymentSheetAnalyticsHelper(isCustom: false, configuration: .init(), analyticsClient: analyticsClient)
        paymentSheetHelper.logShow(showingSavedPMList: true)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_complete_sheet_savedpm_show")
        paymentSheetHelper.logShow(showingSavedPMList: false)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_complete_sheet_newpm_show")

        let flowControllerSUT = PaymentSheetAnalyticsHelper(isCustom: true, configuration: .init(), analyticsClient: analyticsClient)
        flowControllerSUT.logShow(showingSavedPMList: true)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_custom_sheet_savedpm_show")
        flowControllerSUT.logShow(showingSavedPMList: false)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "mc_custom_sheet_newpm_show")
    }

    func testLogSavedPMScreenOptionSelected() {
        func _createHelper(isCustom: Bool) -> PaymentSheetAnalyticsHelper {
            let sut = PaymentSheetAnalyticsHelper(isCustom: isCustom, configuration: .init(), analyticsClient: analyticsClient)
            return sut
        }
        let testcases: [(isCustom: Bool, option: SavedPaymentOptionsViewController.Selection, expectedEvent: String)] = [
            (isCustom: false, option: .applePay, expectedEvent: "mc_complete_paymentoption_applepay_select"),
            (isCustom: false, option: .link, expectedEvent: "mc_complete_paymentoption_link_select"),
            (isCustom: false, option: .add, expectedEvent: "mc_complete_paymentoption_newpm_select"),
            (isCustom: false, option: .saved(paymentMethod: ._testCard()), expectedEvent: "mc_complete_paymentoption_savedpm_select"),
            (isCustom: true, option: .applePay, expectedEvent: "mc_custom_paymentoption_applepay_select"),
            (isCustom: true, option: .link, expectedEvent: "mc_custom_paymentoption_link_select"),
            (isCustom: true, option: .add, expectedEvent: "mc_custom_paymentoption_newpm_select"),
            (isCustom: true, option: .saved(paymentMethod: ._testCard()), expectedEvent: "mc_custom_paymentoption_savedpm_select"),
        ]
        for testcase in testcases {
            let sut = _createHelper(isCustom: testcase.isCustom)
            sut.logSavedPMScreenOptionSelected(option: testcase.option)
            XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, testcase.expectedEvent)
        }
    }

    func testLogFormShownAndInteracted() {
        let sut = PaymentSheetAnalyticsHelper(isCustom: false, configuration: .init(), analyticsClient: analyticsClient)
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
        let testcases: [(isCustom: Bool, paymentOption: PaymentOption, result: PaymentSheetResult, expected: String)] = [
            (isCustom: true, paymentOption: new, result: .completed, expected: "mc_custom_payment_newpm_success"),
            (isCustom: true, paymentOption: saved, result: .completed, expected: "mc_custom_payment_savedpm_success"),
            (isCustom: true, paymentOption: .applePay, result: .completed, expected: "mc_custom_payment_applepay_success"),
            (isCustom: true, paymentOption: .link(option: .wallet), result: .completed, expected: "mc_custom_payment_link_success"),
            (isCustom: true, paymentOption: .new(confirmParams: .init(type: .stripe(.cashApp))), result: .failed(error: error), expected: "mc_custom_payment_newpm_failure"),
            (isCustom: true, paymentOption: saved, result: .failed(error: error), expected: "mc_custom_payment_savedpm_failure"),
            (isCustom: true, paymentOption: .applePay, result: .failed(error: error), expected: "mc_custom_payment_applepay_failure"),
            (isCustom: true, paymentOption: .link(option: .wallet), result: .failed(error: error), expected: "mc_custom_payment_link_failure"),

            (isCustom: false, paymentOption: new, result: .completed, expected: "mc_complete_payment_newpm_success"),
            (isCustom: false, paymentOption: saved, result: .completed, expected: "mc_complete_payment_savedpm_success"),
            (isCustom: false, paymentOption: .applePay, result: .completed, expected: "mc_complete_payment_applepay_success"),
            (isCustom: false, paymentOption: .link(option: .wallet), result: .completed, expected: "mc_complete_payment_link_success"),
            (isCustom: false, paymentOption: .new(confirmParams: .init(type: .stripe(.cashApp))), result: .failed(error: error), expected: "mc_complete_payment_newpm_failure"),
            (isCustom: false, paymentOption: saved, result: .failed(error: error), expected: "mc_complete_payment_savedpm_failure"),
            (isCustom: false, paymentOption: .applePay, result: .failed(error: error), expected: "mc_complete_payment_applepay_failure"),
            (isCustom: false, paymentOption: .link(option: .wallet), result: .failed(error: error), expected: "mc_complete_payment_link_failure"),

        ]
        for (isCustom, paymentOption, result, expected) in testcases {
            let sut = PaymentSheetAnalyticsHelper(
                isCustom: isCustom,
                configuration: .init(),
                analyticsClient: analyticsClient
            )
            sut.intent = ._testValue()
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
        }
    }

    func testLogPaymentSendsDeferredIntentConfirmationType() {
        // Check deferred_intent_confirmation_type gets sent
        let sut = PaymentSheetAnalyticsHelper(
            isCustom: false,
            configuration: .init(),
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
        let sut = PaymentSheetAnalyticsHelper(isCustom: false, configuration: .init(), analyticsClient: analyticsClient)
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
    }

    // MARK: - Helpers

    func makeConfig(
        applePay: PaymentSheet.ApplePayConfiguration?,
        customer: PaymentSheet.CustomerConfiguration?
    ) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        config.applePay = applePay
        config.customer = customer
        return config
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
