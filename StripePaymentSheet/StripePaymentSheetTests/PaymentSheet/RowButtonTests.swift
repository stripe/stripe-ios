//
//  RowButtonTests.swift
//  StripePaymentSheetTests
//

import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet
@testable @_spi(STP) import StripeUICore

@MainActor
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

    func testTrailingLoadingStatePreservesImage() throws {
        let rowButton = SavedPaymentMethodRowButton(
            paymentMethod: STPPaymentMethod._testCard(),
            appearance: .default
        ).rowButton
        rowButton.frame = CGRect(x: 0, y: 0, width: 320, height: 64)

        rowButton.setLoading(true, style: .trailing, animated: false)
        rowButton.layoutIfNeeded()

        let spinner = try XCTUnwrap(rowButton.subviews.first { $0 is ActivityIndicator })
        XCTAssertEqual(rowButton.imageView.alpha, 1)
        XCTAssertEqual(spinner.frame.maxX, rowButton.bounds.maxX - 16)
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
