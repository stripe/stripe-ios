//
//  PMMERowSublabelViewTests.swift
//  StripePaymentSheetTests
//

import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet

final class PMMERowSublabelViewTests: XCTestCase {
    func testSetRowSelected_doesNotExpandWithoutContent() {
        let sut = PMMERowSublabelView(appearance: .default, content: nil)

        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        sut.setRowSelected(true)

        XCTAssertFalse(sut.hasContent)
        XCTAssertFalse(sut.isExpanded)
        XCTAssertTrue(sut.isHidden)
        XCTAssertTrue(sut.promotionTextView.isHidden)
    }

    func testPopulateIfNeeded_expandsWhenRowIsAlreadySelected() {
        let sut = PMMERowSublabelView(appearance: .default, content: nil)

        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        sut.setRowSelected(true)
        sut.populateIfNeeded(makeContent())

        XCTAssertTrue(sut.hasContent)
        XCTAssertTrue(sut.isExpanded)
        XCTAssertFalse(sut.isHidden)
        XCTAssertEqual(sut.promotionTextView.text, "Split your purchase into monthly payments. Learn more")
        XCTAssertFalse(sut.promotionTextView.isHidden)
    }

    func testPopulateIfNeeded_staysHiddenUntilRowIsSelected() {
        let sut = PMMERowSublabelView(appearance: .default, content: nil)

        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        sut.populateIfNeeded(makeContent())

        XCTAssertTrue(sut.hasContent)
        XCTAssertFalse(sut.isExpanded)
        XCTAssertTrue(sut.isHidden)
        XCTAssertTrue(sut.promotionTextView.isHidden)
    }

    func testPopulateIfNeeded_isIdempotent() {
        let sut = PMMERowSublabelView(appearance: .default, content: nil)

        sut.populateIfNeeded(makeContent())
        sut.populateIfNeeded(
            RowButton.PaymentMethodMessagingContent(
                promotion: "Different promo",
                learnMoreText: "Different learn more",
                infoUrl: URL(string: "https://example.com/different")!
            )
        )

        XCTAssertEqual(sut.promotionTextView.text, "Split your purchase into monthly payments. Learn more")
    }

    func testSetRowSelected_notifiesLayoutWhenExpansionChanges() {
        let sut = PMMERowSublabelView(appearance: .default, content: makeContent())
        var callbackCount = 0
        sut.onLayoutNeedsUpdate = {
            callbackCount += 1
        }

        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        sut.setRowSelected(true)
        sut.setRowSelected(true)
        sut.setRowSelected(false)

        XCTAssertEqual(callbackCount, 2)
        XCTAssertTrue(sut.isHidden)
    }

    private func makeContent() -> RowButton.PaymentMethodMessagingContent {
        return RowButton.PaymentMethodMessagingContent(
            promotion: "Split your purchase into monthly payments.",
            learnMoreText: "Learn more",
            infoUrl: URL(string: "https://example.com/affirm")!
        )
    }
}
