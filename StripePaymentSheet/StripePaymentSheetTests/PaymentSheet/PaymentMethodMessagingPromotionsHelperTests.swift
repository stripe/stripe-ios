//
//  PaymentMethodMessagingPromotionsHelperTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class PaymentMethodMessagingPromotionsHelperTests: XCTestCase {
    private let affirmContent = PaymentMethodMessagingPromotionsHelper.PromotionContent(
        promotion: "Split your purchase into monthly payments.",
        learnMoreText: "Learn more",
        infoUrl: URL(string: "https://example.com/affirm")!
    )

    private func makeHelper(
        group: ExperimentGroup,
        prefetchedPromotionContents: [String: PaymentMethodMessagingPromotionsHelper.PromotionContent] = [:],
        analyticsClientV2: MockAnalyticsClientV2? = nil
    ) -> PaymentMethodMessagingPromotionsHelper {
        let analyticsHelper = analyticsClientV2.map {
            PaymentSheetAnalyticsHelper._testValue(analyticsClientV2: $0)
        }
        return PaymentMethodMessagingPromotionsHelper(
            experiment: PaymentMethodMessagingPromotionsExperiment(
                arbId: "arb_123",
                group: group
            ),
            analyticsHelper: analyticsHelper,
            prefetchedPromotionContents: prefetchedPromotionContents
        )
    }

    func testShouldUsePaymentMethodMessagingRow_supportedTypeInTreatment() {
        let helper = makeHelper(group: .treatment)

        XCTAssertTrue(helper.shouldUsePaymentMethodMessagingRow(for: .stripe(.affirm)))
    }

    func testInitWithElementsSession_logsExposureForInitialAssignmentCheck() {
        let analyticsClientV2 = MockAnalyticsClientV2()
        let analyticsHelper = PaymentSheetAnalyticsHelper._testValue(analyticsClientV2: analyticsClientV2)
        let experimentsData = ExperimentsData(
            arbId: "arb_123",
            experimentAssignments: [
                PaymentMethodMessagingPromotionsExperiment.experimentName: .treatment,
            ],
            allResponseFields: [:]
        )

        _ = PaymentMethodMessagingPromotionsHelper(
            elementsSession: STPElementsSession._testValue(experimentsData: experimentsData),
            analyticsHelper: analyticsHelper
        )

        let payloads = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
        XCTAssertEqual(payloads.count, 1)
        XCTAssertEqual(payloads[0]["experiment_retrieved"] as? String, PaymentMethodMessagingPromotionsExperiment.experimentName)
        XCTAssertEqual(payloads[0]["assignment_group"] as? String, ExperimentGroup.treatment.rawValue)
    }

    func testShouldUsePaymentMethodMessagingRow_returnsFalseOutsideTreatmentOrForUnsupportedType() {
        let controlHelper = makeHelper(group: .control)
        let treatmentHelper = makeHelper(group: .treatment)

        XCTAssertFalse(controlHelper.shouldUsePaymentMethodMessagingRow(for: .stripe(.affirm)))
        XCTAssertFalse(treatmentHelper.shouldUsePaymentMethodMessagingRow(for: .stripe(.cashApp)))
    }

    func testShouldUsePaymentMethodMessagingRow_logsExposureOnAssignmentCheck() {
        let analyticsClientV2 = MockAnalyticsClientV2()
        let helper = makeHelper(group: .controlTest, analyticsClientV2: analyticsClientV2)

        XCTAssertFalse(helper.shouldUsePaymentMethodMessagingRow(for: .stripe(.affirm), layout: "vertical"))

        let payloads = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
        XCTAssertEqual(payloads.count, 1)
        XCTAssertEqual(payloads[0]["experiment_retrieved"] as? String, PaymentMethodMessagingPromotionsExperiment.experimentName)
        XCTAssertEqual(payloads[0]["assignment_group"] as? String, ExperimentGroup.controlTest.rawValue)
        XCTAssertEqual(payloads[0]["dimensions-selected_payment_method_type"] as? String, STPPaymentMethodType.affirm.identifier)
        XCTAssertEqual(payloads[0]["dimensions-in_app_elements_layout"] as? String, "vertical")
        XCTAssertNil(payloads[0]["dimensions-promotion_displayed_successfully"])
    }

    func testPromotion_logsSuccessfulDisplayExposure() {
        let analyticsClientV2 = MockAnalyticsClientV2()
        let helper = makeHelper(
            group: .treatment,
            prefetchedPromotionContents: [
                STPPaymentMethodType.affirm.identifier: affirmContent,
            ],
            analyticsClientV2: analyticsClientV2
        )

        let content = helper.promotion(for: .stripe(.affirm), layout: "horizontal")

        XCTAssertEqual(content, affirmContent)
        let payloads = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
        XCTAssertEqual(payloads.count, 2)
        XCTAssertEqual(payloads[1]["dimensions-selected_payment_method_type"] as? String, STPPaymentMethodType.affirm.identifier)
        XCTAssertEqual(payloads[1]["dimensions-in_app_elements_layout"] as? String, "horizontal")
        XCTAssertEqual(payloads[1]["dimensions-promotion_displayed_successfully"] as? String, "true")
    }

    func testPromotion_logsFailedDisplayExposureWhenContentUnavailable() {
        let analyticsClientV2 = MockAnalyticsClientV2()
        let helper = makeHelper(group: .treatment, analyticsClientV2: analyticsClientV2)

        XCTAssertNil(helper.promotion(for: .stripe(.affirm), layout: "vertical"))

        let payloads = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
        XCTAssertEqual(payloads.count, 2)
        XCTAssertEqual(payloads[1]["dimensions-selected_payment_method_type"] as? String, STPPaymentMethodType.affirm.identifier)
        XCTAssertEqual(payloads[1]["dimensions-in_app_elements_layout"] as? String, "vertical")
        XCTAssertEqual(payloads[1]["dimensions-promotion_displayed_successfully"] as? String, "false")
    }

    func testControlGroupLogsExposure() {
        let analyticsClientV2 = MockAnalyticsClientV2()
        let helper = makeHelper(group: .control, analyticsClientV2: analyticsClientV2)

        XCTAssertFalse(helper.shouldUsePaymentMethodMessagingRow(for: .stripe(.affirm), layout: "vertical"))
        XCTAssertNil(helper.promotion(for: .stripe(.affirm), layout: "vertical"))

        let payloads = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
        XCTAssertEqual(payloads.count, 2)
        XCTAssertEqual(payloads[0]["assignment_group"] as? String, ExperimentGroup.control.rawValue)
        XCTAssertEqual(payloads[1]["dimensions-promotion_displayed_successfully"] as? String, "false")
    }
}
