//
//  PaymentMethodMessagingPromotionsHelperTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class PaymentMethodMessagingPromotionsHelperTests: XCTestCase {
    func testIsInTreatmentGroup_treatmentAssignment() {
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
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: analyticsClientV2
        )
        let helper = PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: PaymentSheet.Configuration(),
            paymentMethodTypes: [.stripe(.affirm)],
            analyticsHelper: analyticsHelper
        )

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

    func testIsInTreatmentGroup_controlAssignment() {
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
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: analyticsClientV2
        )
        let helper = PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: PaymentSheet.Configuration(),
            paymentMethodTypes: [.stripe(.affirm)],
            analyticsHelper: analyticsHelper
        )

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

    func testPromotion_returnsNilForUnsupportedType() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"])
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let helper = PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: PaymentSheet.Configuration(),
            paymentMethodTypes: [],
            analyticsHelper: PaymentSheetAnalyticsHelper._testValue()
        )

        XCTAssertNil(helper.promotion(for: .stripe(.cashApp)))
    }
}
