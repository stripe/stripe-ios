//
//  PaymentMethodMessagingPromotionsHelperTests.swift
//  StripePaymentSheetTests
//

import XCTest

@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripePayments

final class PaymentMethodMessagingPromotionsHelperTests: XCTestCase {
    func testShouldUsePaymentMethodMessagingRow_supportedTypeInTreatment() {
        let helper = PaymentMethodMessagingPromotionsHelper(
            experiment: PaymentMethodMessagingPromotionsExperiment(arbId: "", group: .treatment),
            prefetchedPromotionContents: [:]
        )

        XCTAssertTrue(helper.shouldUsePaymentMethodMessagingRow(for: .stripe(.affirm)))
    }

    func testShouldUsePaymentMethodMessagingRow_returnsFalseOutsideTreatmentOrForUnsupportedType() {
        let controlHelper = PaymentMethodMessagingPromotionsHelper(
            experiment: PaymentMethodMessagingPromotionsExperiment(arbId: "", group: .control),
            prefetchedPromotionContents: [:]
        )
        let treatmentHelper = PaymentMethodMessagingPromotionsHelper(
            experiment: PaymentMethodMessagingPromotionsExperiment(arbId: "", group: .treatment),
            prefetchedPromotionContents: [:]
        )

        XCTAssertFalse(controlHelper.shouldUsePaymentMethodMessagingRow(for: .stripe(.affirm)))
        XCTAssertFalse(treatmentHelper.shouldUsePaymentMethodMessagingRow(for: .stripe(.cashApp)))
    }
}
