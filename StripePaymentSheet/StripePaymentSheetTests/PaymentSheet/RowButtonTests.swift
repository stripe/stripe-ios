//
//  RowButtonTests.swift
//  StripePaymentSheetTests
//

import UIKit
import XCTest

@_spi(STP) @testable import StripePaymentSheet

final class RowButtonTests: XCTestCase {
    func testPaymentMethodMessagingRowWithoutContentStartsCollapsed() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            hasSavedCard: false,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertFalse(rowButton.isPaymentMethodMessagingCapable)
        XCTAssertFalse(rowButton.hasPaymentMethodMessagingContent)
        XCTAssertEqual((rowButton.sublabel as? UILabel)?.text, String.Localized.pay_over_time_with_affirm)
    }

    func testPopulatePaymentMethodMessagingIfNeeded_expandsForSelectedRows() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            hasSavedCard: false,
            paymentMethodMessaging: .enabled(content: nil),
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        let content = RowButton.PaymentMethodMessagingContent(
            promotion: "Split your purchase into monthly payments.",
            learnMoreText: "Learn more",
            infoUrl: URL(string: "https://example.com/affirm")!
        )
        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        rowButton.isSelected = true
        rowButton.populatePaymentMethodMessagingIfNeeded(content)

        let textView = rowButton.sublabel as? UITextView
        XCTAssertTrue(rowButton.hasPaymentMethodMessagingContent)
        XCTAssertEqual(textView?.text, "Split your purchase into monthly payments. Learn more")
        XCTAssertFalse(textView?.isHidden ?? true)
    }

    func testPopulatePaymentMethodMessagingIfNeeded_showsContentWhenRowIsNewlySelected() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            hasSavedCard: false,
            paymentMethodMessaging: .enabled(content: nil),
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        let content = RowButton.PaymentMethodMessagingContent(
            promotion: "Split your purchase into monthly payments.",
            learnMoreText: "Learn more",
            infoUrl: URL(string: "https://example.com/affirm")!
        )
        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        let textView = rowButton.sublabel as? UITextView

        XCTAssertTrue(rowButton.isPaymentMethodMessagingCapable)
        XCTAssertFalse(rowButton.hasPaymentMethodMessagingContent)
        XCTAssertTrue(textView?.isHidden ?? false)

        rowButton.populatePaymentMethodMessagingIfNeeded(content)

        XCTAssertTrue(rowButton.hasPaymentMethodMessagingContent)
        XCTAssertEqual(textView?.text, "Split your purchase into monthly payments. Learn more")
        XCTAssertTrue(textView?.isHidden ?? false)

        rowButton.isSelected = true

        XCTAssertFalse(textView?.isHidden ?? true)
    }
}
