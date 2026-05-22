//
//  PaymentMethodMessagingSublabelViewTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
import UIKit
import XCTest

@MainActor
class PaymentMethodMessagingSublabelViewTests: XCTestCase {

    // MARK: - Helper

    private func makeHelper(
        isInTreatment: Bool,
        contents: [String: PaymentMethodMessagingPromotionsHelper.PromotionContent] = [:]
    ) -> PaymentMethodMessagingPromotionsHelper {
        let experiment = PaymentMethodMessagingPromotionsExperiment(
            arbId: "test_arb_id",
            group: isInTreatment ? .treatment : .control
        )
        return PaymentMethodMessagingPromotionsHelper(
            experiment: experiment,
            prefetchedPromotionContents: contents
        )
    }

    private func makePromotionContent() -> PaymentMethodMessagingPromotionsHelper.PromotionContent {
        PaymentMethodMessagingPromotionsHelper.PromotionContent(
            promotion: "Pay in 4 interest-free payments",
            learnMoreText: "Learn more",
            infoUrl: URL(string: "https://stripe.com/learn-more")!
        )
    }

    private func makeSublabelView(
        paymentMethodType: PaymentSheet.PaymentMethodType = .stripe(.klarna),
        helper: PaymentMethodMessagingPromotionsHelper
    ) -> RowButton.PaymentMethodMessagingSublabelView {
        RowButton.PaymentMethodMessagingSublabelView(
            appearance: .default,
            paymentMethodType: paymentMethodType,
            promotionsHelper: helper
        )
    }

    // MARK: - updateSelectedState tests

    func testUpdateSelectedState_true_withContent_expands() {
        let helper = makeHelper(
            isInTreatment: true,
            contents: ["klarna": makePromotionContent()]
        )
        let sublabelView = makeSublabelView(helper: helper)

        sublabelView.updateSelectedState(true)

        XCTAssertFalse(sublabelView.isHidden)
    }

    func testUpdateSelectedState_false_collapses() {
        let helper = makeHelper(
            isInTreatment: true,
            contents: ["klarna": makePromotionContent()]
        )
        let sublabelView = makeSublabelView(helper: helper)

        sublabelView.updateSelectedState(true)
        sublabelView.updateSelectedState(false)

        // After collapse animation starts, isHidden should be set to true
        // We verify the state was toggled by checking isHidden after the animation block runs
        // Since animations execute synchronously in tests (no animation block), this should work
        XCTAssertTrue(sublabelView.isHidden)
    }

    func testUpdateSelectedState_true_withoutContent_doesNotExpand() {
        let helper = makeHelper(
            isInTreatment: true,
            contents: [:]  // No content for klarna
        )
        let sublabelView = makeSublabelView(helper: helper)

        sublabelView.updateSelectedState(true)

        XCTAssertTrue(sublabelView.isHidden)
    }

    func testUpdateSelectedState_true_calledTwice_doesNotReExpand() {
        let helper = makeHelper(
            isInTreatment: true,
            contents: ["klarna": makePromotionContent()]
        )
        let sublabelView = makeSublabelView(helper: helper)

        var layoutUpdateCount = 0
        sublabelView.onLayoutNeedsUpdate = {
            layoutUpdateCount += 1
        }

        sublabelView.updateSelectedState(true)
        let countAfterFirstExpand = layoutUpdateCount

        sublabelView.updateSelectedState(true)
        let countAfterSecondExpand = layoutUpdateCount

        XCTAssertEqual(countAfterFirstExpand, countAfterSecondExpand, "Second call to updateSelectedState(true) should be a no-op")
    }

    // MARK: - RowButton.makeForPaymentMethodType branching logic tests

    func testMakeForPaymentMethodType_treatmentGroup_supportedMethod_usesPMMSublabel() {
        let helper = makeHelper(
            isInTreatment: true,
            contents: ["klarna": makePromotionContent()]
        )

        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.klarna),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel is RowButton.PaymentMethodMessagingSublabelView)
    }

    func testMakeForPaymentMethodType_treatmentGroup_unsupportedMethod_usesPlainSublabel() {
        let helper = makeHelper(
            isInTreatment: true,
            contents: [:]
        )

        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.card),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel is RowButton.PlainSublabelView)
    }

    func testMakeForPaymentMethodType_controlGroup_supportedMethod_usesPlainSublabel() {
        let helper = makeHelper(
            isInTreatment: false,
            contents: [:]
        )

        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.klarna),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel is RowButton.PlainSublabelView)
    }

    func testMakeForPaymentMethodType_nilHelper_usesPlainSublabel() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.klarna),
            hasSavedCard: false,
            promotionsHelper: nil,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel is RowButton.PlainSublabelView)
    }

    func testMakeForPaymentMethodType_treatmentGroup_affirm_usesPMMSublabel() {
        let helper = makeHelper(
            isInTreatment: true,
            contents: ["affirm": makePromotionContent()]
        )

        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel is RowButton.PaymentMethodMessagingSublabelView)
    }

    func testMakeForPaymentMethodType_treatmentGroup_afterpayClearpay_usesPMMSublabel() {
        let helper = makeHelper(
            isInTreatment: true,
            contents: ["afterpay_clearpay": makePromotionContent()]
        )

        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.afterpayClearpay),
            hasSavedCard: false,
            promotionsHelper: helper,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )

        XCTAssertTrue(rowButton.sublabel is RowButton.PaymentMethodMessagingSublabelView)
    }
}
