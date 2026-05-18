//
//  RowButtonTests.swift
//  StripePaymentSheetTests
//

import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet

final class RowButtonTests: XCTestCase {
    func testPaymentMethodMessagingRowCanStartWithoutContent() throws {
        let sublabel = PMMERowSublabelView(appearance: .default, content: nil)
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            hasSavedCard: false,
            sublabel: sublabel,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel === sublabel)
        XCTAssertFalse(sublabel.hasContent)
        XCTAssertFalse(sublabel.isExpanded)
        XCTAssertTrue(sublabel.promotionTextView.isHidden)
    }

    func testPlainSublabelHelperHidesAndShowsLabel() throws {
        let sublabel = RowButton.makePlainSublabel(
            text: RowButton.makeLinkPlainSublabelText(),
            appearance: .default,
            isEmbedded: false
        )
        let rowButton = RowButton.makeForLink(appearance: .default, sublabel: sublabel, linkBrand: .link) { _ in }
        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        sublabel.setRowButtonPlainSublabelText(nil, animated: false) {
            rowButton.didUpdateSublabelLayout()
        }
        XCTAssertNil(sublabel.text)
        XCTAssertTrue(sublabel.isHidden)

        sublabel.setRowButtonPlainSublabelText("Updated subtitle", animated: false) {
            rowButton.didUpdateSublabelLayout()
        }
        XCTAssertEqual(sublabel.text, "Updated subtitle")
        XCTAssertFalse(sublabel.isHidden)
    }
}
