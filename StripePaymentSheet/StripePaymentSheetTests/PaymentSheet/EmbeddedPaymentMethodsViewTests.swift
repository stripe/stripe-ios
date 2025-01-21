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

        // Delegate methods should not be called upon initialization
        XCTAssertEqual(mockDelegate.calls, [])
        XCTAssertNil(embeddedView.selection)

        // Simulate tapping Cash App and verify delegate is called
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.cashApp)))
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection, .didTapPaymentMethodRow])
        XCTAssertEqual(embeddedView.selection, .new(paymentMethodType: .stripe(.cashApp)), "Cash App Pay should be the current selection")
        mockDelegate.calls = []

        // Simulate tapping Klarna and verify delegate is called
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.klarna)))
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection, .didTapPaymentMethodRow])
        XCTAssertEqual(embeddedView.selection, .new(paymentMethodType: .stripe(.klarna)), "Klarna should be the current selection")
        mockDelegate.calls = []

        // Resetting selection to last selection...
        embeddedView.resetSelectionToLastSelection()
        // ...should go back to Cash App
        XCTAssertEqual(embeddedView.selection, .new(paymentMethodType: .stripe(.cashApp)))
        // ...and call/not call the various delegate methods
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection])
        mockDelegate.calls = []

        // Resetting...
        embeddedView.resetSelection()
        // ...should go to nil
        XCTAssertNil(embeddedView.selection)
        // ...and call/not call the various delegate methods
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection])
        mockDelegate.calls = []

        // Simulate tapping PayPal and verify delegate is called
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.payPal)))
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection, .didTapPaymentMethodRow])
        XCTAssertEqual(embeddedView.selection, .new(paymentMethodType: .stripe(.payPal)), "PayPal should be the current selection")
        mockDelegate.calls = []

        // Simulate tapping PayPal again (same selection) and verify delegate is NOT called
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.payPal)))
        XCTAssertEqual(mockDelegate.calls, [.didTapPaymentMethodRow])
        XCTAssertEqual(embeddedView.selection, .new(paymentMethodType: .stripe(.payPal)), "PayPal should still be the current selection")
    }
}

private class MockEmbeddedPaymentMethodsViewDelegate: EmbeddedPaymentMethodsViewDelegate {
    enum Methods: String, CustomDebugStringConvertible {
        var debugDescription: String { rawValue }

        case didUpdateHeight
        case didTapPaymentMethodRow
        case didUpdateSelection
    }
    // we should call didTapPaymentMethodRow *after* didUpdateSelection, so maintain an ordered list of calls
    var calls: [Methods] = []

    func embeddedPaymentMethodsViewDidUpdateHeight() {
        calls.append(.didUpdateHeight)
    }

    func embeddedPaymentMethodsViewDidTapPaymentMethodRow() {
        calls.append(.didTapPaymentMethodRow)
    }

    func embeddedPaymentMethodsViewDidUpdateSelection() {
        calls.append(.didUpdateSelection)
    }

    func embeddedPaymentMethodsViewDidTapViewMoreSavedPaymentMethods(selectedSavedPaymentMethod: STPPaymentMethod?) {
    }
}
