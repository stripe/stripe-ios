//
//  PaymentMethodMessagingSublabelSnapshotTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
import UIKit
import XCTest

@MainActor
class PaymentMethodMessagingSublabelSnapshotTests: STPSnapshotTestCase {

    // MARK: - Helper

    private func makeHelper(
        contents: [String: PaymentMethodMessagingPromotionsHelper.PromotionContent]
    ) -> PaymentMethodMessagingPromotionsHelper {
        let experiment = PaymentMethodMessagingPromotionsExperiment(
            arbId: "test_arb_id",
            group: .treatment
        )
        return PaymentMethodMessagingPromotionsHelper(
            experiment: experiment,
            prefetchedPromotionContents: contents
        )
    }

    private func makePromotionContent(
        promotion: String = "Pay in 4 interest-free payments of $12.50",
        learnMoreText: String = "Learn more"
    ) -> PaymentMethodMessagingPromotionsHelper.PromotionContent {
        PaymentMethodMessagingPromotionsHelper.PromotionContent(
            promotion: promotion,
            learnMoreText: learnMoreText,
            infoUrl: URL(string: "https://stripe.com/learn-more")!
        )
    }

    // MARK: - Snapshot Tests

    func testRowButton_klarna_pmmSublabel_selected() {
        let helper = makeHelper(contents: ["klarna": makePromotionContent()])
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.klarna),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        rowButton.isSelected = true
        verify(rowButton)
    }

    func testRowButton_affirm_pmmSublabel_selected() {
        let helper = makeHelper(contents: ["affirm": makePromotionContent(promotion: "As low as $12/mo with Affirm")])
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        rowButton.isSelected = true
        verify(rowButton)
    }

    func testRowButton_afterpay_pmmSublabel_selected() {
        let helper = makeHelper(contents: ["afterpay_clearpay": makePromotionContent(promotion: "4 interest-free payments of $25.00")])
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.afterpayClearpay),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        rowButton.isSelected = true
        verify(rowButton)
    }

    func testRowButton_klarna_pmmSublabel_unselected() {
        let helper = makeHelper(contents: ["klarna": makePromotionContent()])
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.klarna),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        // Do not select — sublabel should remain hidden
        verify(rowButton)
    }

    func testRowButton_klarna_pmmSublabel_customAppearance() {
        var appearance = PaymentSheet.Appearance.default
        appearance.colors.primary = .systemPurple
        appearance.colors.text = .darkGray
        appearance.font.base = .boldSystemFont(ofSize: 14)

        let helper = makeHelper(contents: ["klarna": makePromotionContent()])
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.klarna),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: appearance,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        rowButton.isSelected = true
        verify(rowButton)
    }

    // MARK: - Verify

    private func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
