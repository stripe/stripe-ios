//
//  EmbeddedPaymentMethodsViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/4/24.
//

@_spi(EmbeddedPaymentElementPrivateBeta) @testable import StripePaymentSheet
import XCTest

@MainActor
final class EmbeddedPaymentMethodsViewTests: XCTestCase {

    // MARK: EmbeddedPaymentMethodsViewDelegate test
    func testEmbeddedPaymentMethodsView_delegateTest() {
        let mockMandateProvider = MockMandateProvider { paymentMethodType in
            if paymentMethodType == .stripe(.cashApp) {
                let longText = String(repeating: "This is a long mandate text. ", count: 20)
                return NSAttributedString(string: longText)
            }
            if paymentMethodType == .stripe(.payPal) {
                let mediumText = String(repeating: "This is a long mandate text. ", count: 10)
                return NSAttributedString(string: mediumText)
            }
            if paymentMethodType == .stripe(.amazonPay) {
                let shortText = String(repeating: "This is a long mandate text. ", count: 3)
                return NSAttributedString(string: shortText)
            }
            return nil
        }

        let mockDelegate = MockEmbeddedPaymentMethodsViewDelegate()

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: nil,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.klarna), .stripe(.payPal)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: mockMandateProvider
        )
        embeddedView.delegate = mockDelegate
        embeddedView.autosizeHeight(width: 300)

        let rowButtons = embeddedView.stackView.arrangedSubviews.compactMap { $0 as? RowButton }

        // Delegate methods should not be called upon initialization
        XCTAssertFalse(mockDelegate.didCallHeightDidChange, "heightDidChange should not be called on init")
        XCTAssertFalse(mockDelegate.didCallSelectionDidUpdate, "selectionDidUpdate should not be called on init")
        XCTAssertNil(embeddedView.selection)

        // Simulate tapping Cash App and verify delegate is called
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.cashApp)))
        XCTAssertTrue(mockDelegate.didCallHeightDidChange, "didCallHeightDidChange should be called when selection changes to show a mandate")
        XCTAssertTrue(mockDelegate.didCallSelectionDidUpdate, "selectionDidUpdate should be called when selection changes")
        XCTAssertEqual(embeddedView.selection, .new(paymentMethodType: .stripe(.cashApp)), "Cash App Pay should be the current selection")
        mockDelegate.reset()

        // Simulate tapping Klarna and verify delegate is called
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.klarna)))
        XCTAssertTrue(mockDelegate.didCallHeightDidChange, "didCallHeightDidChange should be called when selection changes to show a different sized mandate")
        XCTAssertTrue(mockDelegate.didCallSelectionDidUpdate, "selectionDidUpdate should be called when selection changes")
        XCTAssertEqual(embeddedView.selection, .new(paymentMethodType: .stripe(.klarna)), "Klarna should be the current selection")
        mockDelegate.reset()

        // Simulate tapping PayPal and verify delegate is called
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.payPal)))
        XCTAssertTrue(mockDelegate.didCallHeightDidChange, "didCallHeightDidChange should be called when selection changes to show a different sized mandate")
        XCTAssertTrue(mockDelegate.didCallSelectionDidUpdate, "selectionDidUpdate should be called when selection changes")
        XCTAssertEqual(embeddedView.selection, .new(paymentMethodType: .stripe(.payPal)), "PayPal should be the current selection")
        mockDelegate.reset()

        // Simulate tapping PayPal again (same selection) and verify delegate is NOT called
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.payPal)))
        XCTAssertFalse(mockDelegate.didCallHeightDidChange, "didCallHeightDidChange should not be called when the same selection is selected again")
        XCTAssertFalse(mockDelegate.didCallSelectionDidUpdate, "selectionDidUpdate should not be called when the same selection is selected again")
        XCTAssertEqual(embeddedView.selection, .new(paymentMethodType: .stripe(.payPal)), "PayPal should still be the current selection")
    }

}

private class MockEmbeddedPaymentMethodsViewDelegate: EmbeddedPaymentMethodsViewDelegate {
    private(set) var didCallHeightDidChange = false
    private(set) var didCallSelectionDidUpdate = false

    func heightDidChange() {
        didCallHeightDidChange = true
    }

    func updateSelectionState(isNewSelection: Bool) {
        if isNewSelection {
            didCallSelectionDidUpdate = true
        }
    }

    func presentSavedPaymentMethods(selectedSavedPaymentMethod: STPPaymentMethod?) {
    }

    func reset() {
        didCallHeightDidChange = false
        didCallSelectionDidUpdate = false
    }
}
