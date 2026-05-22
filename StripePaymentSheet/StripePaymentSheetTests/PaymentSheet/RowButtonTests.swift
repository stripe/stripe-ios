//
//  RowButtonTests.swift
//  StripePaymentSheetTests
//

import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet

final class RowButtonTests: XCTestCase {
    func testRowButtonForPaymentMethodType_usesPaymentMethodMessagingSublabelWhenInTreatment() {
        let promotionsHelper = PaymentMethodMessagingPromotionsHelper._testValue()
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            currency: "USD",
            hasSavedCard: false,
            accessoryView: nil,
            promoText: nil,
            promotionsHelper: promotionsHelper,
            appearance: .default,
            originalCornerRadius: nil,
            shouldAnimateOnPress: false,
            isEmbedded: false,
            didTap: { _ in }
        )

        XCTAssertEqual(rowButton.label.text, "Affirm")
    }
}
