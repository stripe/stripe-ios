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

    func testFloatingRowShadowMatchesBoundsAfterResizing() throws {
        // Given a payment method row laid out at the presenter's wider size
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.card),
            hasSavedCard: false,
            promotionsHelper: nil,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        rowButton.frame = CGRect(x: 0, y: 0, width: 700, height: 64)
        rowButton.layoutIfNeeded()
        rowButton.updateSelectedState(true, willDisplayForm: false)
        let background = try XCTUnwrap(rowButton.subviews.first { $0 is ShadowedRoundedRectangle })
        XCTAssertEqual(try XCTUnwrap(background.layer.shadowPath).boundingBoxOfPath, background.bounds)

        for width: CGFloat in [320, 700] {
            // When the sheet narrows the row or the device unfolds, without changing its selection
            rowButton.frame.size.width = width
            rowButton.layoutIfNeeded()

            // Then the shadow follows the new bounds instead of extending past the row
            XCTAssertEqual(background.bounds.width, width)
            XCTAssertEqual(try XCTUnwrap(background.layer.shadowPath).boundingBoxOfPath, background.bounds)
        }
    }

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
