//
//  RowButtonTests.swift
//  StripePaymentSheetTests
//

import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet

final class RowButtonTests: XCTestCase {
    func testRowButtonForPaymentMethodType_usesPaymentMethodMessagingSublabelWhenInTreatment() {
        let promotionsHelper = PaymentMethodMessagingPromotionsHelper._testValueInTreatment()
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            currency: "USD",
            hasSavedCard: false,
            promotionsHelper: promotionsHelper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssert(rowButton.sublabel is RowButton.PaymentMethodMessagingSublabelView)
    }
}
