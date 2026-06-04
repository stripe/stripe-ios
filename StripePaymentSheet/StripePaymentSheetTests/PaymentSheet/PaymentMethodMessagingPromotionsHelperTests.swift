//
//  PaymentMethodMessagingPromotionsHelperTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class PaymentMethodMessagingPromotionsHelperTests: APIStubbedTestCase {

    override func setUp() {
        super.setUp()
        stubPMMEEndpoint()
    }

    private func stubPMMEEndpoint() {
        stub { urlRequest in
            urlRequest.url?.host == "ppm.stripe.com"
        } response: { _ in
            let json: [String: Any] = [
                "content": ["images": []],
                "payment_plan_groups": [],
            ]
            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }
    }

    private func stubbedConfiguration() -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_123"
        config.apiClient = apiClient
        return config
    }

    func testIsInTreatmentGroup_treatmentAssignment() throws {
        let analyticsClientV2 = MockAnalyticsClientV2()
        let arbId = "arb_123"
        let experimentsData = ExperimentsData(
            arbId: arbId,
            experimentAssignments: [
                PaymentMethodMessagingPromotionsExperiment.experimentName: .treatment,
            ],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(experimentsData: experimentsData)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let configuration = stubbedConfiguration()
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: configuration,
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: analyticsClientV2
        )
        let helper = try XCTUnwrap(PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: configuration,
            paymentMethodTypes: [.stripe(.affirm)],
            analyticsHelper: analyticsHelper
        ))

        XCTAssertTrue(helper.isInTreatmentGroup)

        // Verify exposure was logged exactly once with correct parameters
        let payloads = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
        XCTAssertEqual(payloads.count, 1)
        guard let payload = payloads.first else {
            return XCTFail("Expected exposure event to be logged")
        }
        XCTAssertEqual(payload["arb_id"] as? String, arbId)
        XCTAssertEqual(payload["experiment_retrieved"] as? String, PaymentMethodMessagingPromotionsExperiment.experimentName)
        XCTAssertEqual(payload["assignment_group"] as? String, ExperimentGroup.treatment.rawValue)

        // Second access should not log again
        _ = helper.isInTreatmentGroup
        XCTAssertEqual(analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).count, 1)
    }

    func testIsInTreatmentGroup_controlAssignment() throws {
        let analyticsClientV2 = MockAnalyticsClientV2()
        let arbId = "arb_123"
        let experimentsData = ExperimentsData(
            arbId: arbId,
            experimentAssignments: [
                PaymentMethodMessagingPromotionsExperiment.experimentName: .control,
            ],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(experimentsData: experimentsData)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let configuration = stubbedConfiguration()
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: configuration,
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: analyticsClientV2
        )
        let helper = try XCTUnwrap(PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: configuration,
            paymentMethodTypes: [.stripe(.affirm)],
            analyticsHelper: analyticsHelper
        ))

        XCTAssertFalse(helper.isInTreatmentGroup)

        // Verify exposure was logged exactly once with correct parameters
        let payloads = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
        XCTAssertEqual(payloads.count, 1)
        guard let payload = payloads.first else {
            return XCTFail("Expected exposure event to be logged")
        }
        XCTAssertEqual(payload["arb_id"] as? String, arbId)
        XCTAssertEqual(payload["experiment_retrieved"] as? String, PaymentMethodMessagingPromotionsExperiment.experimentName)
        XCTAssertEqual(payload["assignment_group"] as? String, ExperimentGroup.control.rawValue)

        // Second access should not log again
        _ = helper.isInTreatmentGroup
        XCTAssertEqual(analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).count, 1)
    }

    func testPromotion_returnsNilForUnsupportedType() async throws {
        let experimentsData = ExperimentsData(
            arbId: "arb_123",
            experimentAssignments: [PaymentMethodMessagingPromotionsExperiment.experimentName: .treatment],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(orderedPaymentMethodTypes: [.card], experimentsData: experimentsData)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let configuration = stubbedConfiguration()
        let helper = try XCTUnwrap(PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: configuration,
            paymentMethodTypes: [],
            analyticsHelper: PaymentSheetAnalyticsHelper._testValue()
        ))

        helper.fetchData()
        await helper.fetchTask?.value

        XCTAssertNil(helper.promotion(for: .stripe(.cashApp)))
    }

    // MARK: - Analytics

    func testFetchData_logsFetchBeginEvent() async throws {
        let analyticsClient = STPTestingAnalyticsClient()
        let experimentsData = ExperimentsData(
            arbId: "arb_123",
            experimentAssignments: [PaymentMethodMessagingPromotionsExperiment.experimentName: .treatment],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(orderedPaymentMethodTypes: [.card], experimentsData: experimentsData)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let configuration = stubbedConfiguration()
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: configuration,
            analyticsClient: analyticsClient
        )
        let helper = try XCTUnwrap(PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: configuration,
            paymentMethodTypes: [.stripe(.affirm)],
            analyticsHelper: analyticsHelper
        ))

        helper.fetchData()
        await helper.fetchTask?.value

        let fetchBeginEvents = analyticsClient._testLogHistory.filter { $0["event"] as? String == "payment_method_messaging_fetch_begin" }
        XCTAssertEqual(fetchBeginEvents.count, 1)
    }

    func testFetchData_controlGroup_doesNotLogFetchBegin() async throws {
        let analyticsClient = STPTestingAnalyticsClient()
        let experimentsData = ExperimentsData(
            arbId: "arb_123",
            experimentAssignments: [PaymentMethodMessagingPromotionsExperiment.experimentName: .control],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(orderedPaymentMethodTypes: [.card], experimentsData: experimentsData)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let configuration = stubbedConfiguration()
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: configuration,
            analyticsClient: analyticsClient
        )
        let helper = try XCTUnwrap(PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: configuration,
            paymentMethodTypes: [.stripe(.affirm)],
            analyticsHelper: analyticsHelper
        ))

        helper.fetchData()
        await helper.fetchTask?.value

        let fetchBeginEvents = analyticsClient._testLogHistory.filter { $0["event"] as? String == "payment_method_messaging_fetch_begin" }
        XCTAssertEqual(fetchBeginEvents.count, 0)
    }

    func testLogDisplayedAnalytic_afterFetch_logsDurationAndSuccess() async throws {
        let analyticsClient = STPTestingAnalyticsClient()
        let experimentsData = ExperimentsData(
            arbId: "arb_123",
            experimentAssignments: [PaymentMethodMessagingPromotionsExperiment.experimentName: .treatment],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(orderedPaymentMethodTypes: [.card], experimentsData: experimentsData)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let configuration = stubbedConfiguration()
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: configuration,
            analyticsClient: analyticsClient
        )
        let helper = try XCTUnwrap(PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: configuration,
            paymentMethodTypes: [.stripe(.affirm)],
            analyticsHelper: analyticsHelper
        ))

        helper.fetchData()
        await helper.fetchTask?.value
        helper.logDisplayedAnalytic(displayedSuccessfully: true)

        let displayedEvents = analyticsClient._testLogHistory.filter { $0["event"] as? String == "payment_method_messaging_displayed" }
        XCTAssertEqual(displayedEvents.count, 1)
        guard let event = displayedEvents.first else { return }
        XCTAssertEqual(event["displayed_successfully"] as? Bool, true)
        XCTAssertGreaterThanOrEqual(event["duration"] as? Double ?? -1, 0)
    }

    func testLogDisplayedAnalytic_withoutFetch_logsDurationZero() throws {
        let analyticsClient = STPTestingAnalyticsClient()
        let experimentsData = ExperimentsData(
            arbId: "arb_123",
            experimentAssignments: [PaymentMethodMessagingPromotionsExperiment.experimentName: .treatment],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(orderedPaymentMethodTypes: [.card], experimentsData: experimentsData)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let configuration = stubbedConfiguration()
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: configuration,
            analyticsClient: analyticsClient
        )
        let helper = try XCTUnwrap(PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: configuration,
            paymentMethodTypes: [],
            analyticsHelper: analyticsHelper
        ))

        helper.logDisplayedAnalytic(displayedSuccessfully: false)

        let displayedEvents = analyticsClient._testLogHistory.filter { $0["event"] as? String == "payment_method_messaging_displayed" }
        XCTAssertEqual(displayedEvents.count, 1)
        guard let event = displayedEvents.first else { return }
        XCTAssertEqual(event["displayed_successfully"] as? Bool, false)
        XCTAssertEqual(event["duration"] as? Double, 0)
    }
}
