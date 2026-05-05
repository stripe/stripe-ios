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
            experiment: PaymentMethodMessagingPromotionsExperiment(group: .treatment),
            prefetchedPromotionContents: [:]
        )

        XCTAssertTrue(helper.shouldUsePaymentMethodMessagingRow(for: .stripe(.affirm)))
    }

    func testShouldUsePaymentMethodMessagingRow_returnsFalseOutsideTreatmentOrForUnsupportedType() {
        let controlHelper = PaymentMethodMessagingPromotionsHelper(
            experiment: PaymentMethodMessagingPromotionsExperiment(group: .control),
            prefetchedPromotionContents: [:]
        )
        let treatmentHelper = PaymentMethodMessagingPromotionsHelper(
            experiment: PaymentMethodMessagingPromotionsExperiment(group: .treatment),
            prefetchedPromotionContents: [:]
        )

        XCTAssertFalse(controlHelper.shouldUsePaymentMethodMessagingRow(for: .stripe(.affirm)))
        XCTAssertFalse(treatmentHelper.shouldUsePaymentMethodMessagingRow(for: .stripe(.cashApp)))
    }
}
