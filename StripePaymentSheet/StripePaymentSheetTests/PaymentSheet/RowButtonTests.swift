//
//  RowButtonTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import UIKit
import XCTest

final class RowButtonTests: XCTestCase {
    func testSupportedPaymentMethodUsesBNPLComponentWhenBNPLDataProvided() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.klarna),
            hasSavedCard: false,
            bnplData: .init(
                promotion: "Pay in 4",
                learnMoreText: "Learn more",
                infoURL: URL(string: "https://stripe.com")!
            ),
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel is RowButtonBNPLSublabel)
        XCTAssertNil(rowButton.plainSublabel)
    }

    func testSupportedPaymentMethodWithoutBNPLDataUsesPlainComponent() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            hasSavedCard: false,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel is RowButtonPlainSublabel)
        XCTAssertNotNil(rowButton.plainSublabel)
    }

    func testUnsupportedPaymentMethodIgnoresBNPLData() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.card),
            hasSavedCard: false,
            bnplData: .init(
                promotion: "Pay in 4",
                learnMoreText: "Learn more",
                infoURL: URL(string: "https://stripe.com")!
            ),
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel is RowButtonPlainSublabel)
        XCTAssertNotNil(rowButton.plainSublabel)
    }

    func testBNPLVariantDoesNotActivateHeightConstraint() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.afterpayClearpay),
            hasSavedCard: false,
            bnplData: .init(
                promotion: "Pay over time",
                learnMoreText: "Learn more",
                infoURL: URL(string: "https://stripe.com")!
            ),
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertFalse(rowButton.heightConstraint?.isActive ?? false)
    }

    func testShowAndRemoveChangeButtonUpdatesPlainSublabel() {
        let accessoryView = UIView()
        accessoryView.isHidden = true

        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.card),
            hasSavedCard: false,
            accessoryView: accessoryView,
            appearance: .default,
            shouldAnimateOnPress: false,
            isEmbedded: true,
            didTap: { _ in }
        )

        rowButton.showChangeButton(sublabel: "•••• 4242")

        XCTAssertEqual(rowButton.plainSublabel?.label.text, "•••• 4242")
        XCTAssertFalse(accessoryView.isHidden)

        rowButton.removeChangeButton(shouldClearSublabel: true)

        XCTAssertNil(rowButton.plainSublabel?.label.text)
        XCTAssertTrue(accessoryView.isHidden)
    }
}
