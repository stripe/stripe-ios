//
//  RowButtonTests.swift
//  StripePaymentSheetTests
//

import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet

final class RowButtonTests: XCTestCase {
    func testLoadingStatePreservesKeyContentAlpha() {
        let rowButton = SavedPaymentMethodRowButton(
            paymentMethod: STPPaymentMethod._testCard(),
            appearance: .default
        ).rowButton
        rowButton.setKeyContent(alpha: 0.5)

        rowButton.setLoading(true, animated: false)
        XCTAssertEqual(rowButton.imageView.alpha, 0)

        rowButton.setLoading(false, animated: false)
        XCTAssertEqual(rowButton.imageView.alpha, 0.5)
    }

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
