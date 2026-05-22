//
//  PaymentMethodMessagingPromotionsHelperTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class PaymentMethodMessagingPromotionsHelperTests: XCTestCase {
    func testIsInTreatmentGroup_treatmentAssignment() {
        let experimentsData = ExperimentsData(
            arbId: "arb_123",
            experimentAssignments: [
                PaymentMethodMessagingPromotionsExperiment.experimentName: .treatment,
            ],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(experimentsData: experimentsData)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let helper = PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: PaymentSheet.Configuration(),
            paymentMethodTypes: [.stripe(.affirm)],
            analyticsHelper: PaymentSheetAnalyticsHelper._testValue()
        )

        XCTAssertTrue(helper.isInTreatmentGroup)
    }

    func testIsInTreatmentGroup_controlAssignment() {
        let experimentsData = ExperimentsData(
            arbId: "arb_123",
            experimentAssignments: [
                PaymentMethodMessagingPromotionsExperiment.experimentName: .control,
            ],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(experimentsData: experimentsData)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let helper = PaymentMethodMessagingPromotionsHelper(
            elementsSession: elementsSession,
            intent: intent,
            configuration: PaymentSheet.Configuration(),
            paymentMethodTypes: [.stripe(.affirm)],
            analyticsHelper: PaymentSheetAnalyticsHelper._testValue()
        )

        XCTAssertFalse(helper.isInTreatmentGroup)
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
