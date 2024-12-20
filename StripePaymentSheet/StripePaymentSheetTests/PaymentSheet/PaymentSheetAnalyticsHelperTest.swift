//
//  PaymentSheetAnalyticsHelperTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 8/2/24.
//

@testable@_spi(STP) import StripeCore
@_spi(STP)@testable import StripeCoreTestUtils
@testable@_spi(STP)@_spi(EmbeddedPaymentElementPrivateBeta) import StripePaymentSheet
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
            case .complete, .flowController:
                XCTAssertEqual("automatic", lastEvent.additionalParams[jsonDict: "mpe_config"]?["payment_method_layout"] as? String)
            case .embedded:
                XCTAssertEqual("continue", lastEvent.additionalParams[jsonDict: "mpe_config"]?["form_sheet_action"] as? String)
                XCTAssertEqual(true, lastEvent.additionalParams[jsonDict: "mpe_config"]?["embedded_view_displays_mandate_text"] as? Bool)
            }
        }
    }

    func testLogLoadFailed() {
        let sut = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
        // Load started -> failed
        sut.logLoadStarted()
        sut.logLoadFailed(error: NSError(domain: "domain", code: 1))
        XCTAssertEqual(analyticsClient._testLogHistory[0]["event"] as? String, "mc_load_started")
        XCTAssertEqual(analyticsClient._testLogHistory[1]["event"] as? String, "mc_load_failed")
        XCTAssertLessThan(analyticsClient._testLogHistory[1]["duration"] as! Double, 1.0)
    }

    func testLogLoadSucceeded() {
        let sut = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
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
        for (integrationShape, paymentOption, result, expected) in testcases {
            let sut = PaymentSheetAnalyticsHelper(
                integrationShape: integrationShape,
                configuration: PaymentSheet.Configuration(),
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
    }

    func testLogPaymentLinkContextWithLinkedBank() {
        let instantDebitsLinkedBank = InstantDebitsLinkedBank(
            paymentMethod: LinkBankPaymentMethod(id: "paymentMethodId"),
            bankName: nil,
            last4: nil,
            linkMode: .linkPaymentMethod
        )
        let linkCardBrandLinkedBank = InstantDebitsLinkedBank(
            paymentMethod: LinkBankPaymentMethod(id: "paymentMethodId"),
            bankName: nil,
            last4: nil,
            linkMode: .linkCardBrand
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

    // MARK: - Helpers

    func makeConfig(
        applePay: PaymentSheet.ApplePayConfiguration?,
        customer: PaymentSheet.CustomerConfiguration?,
        integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape
    ) -> PaymentElementConfiguration {
        switch integrationShape {
        case .flowController, .complete:
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
