//
//  EmbeddedPaymentMethodsViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/4/24.
//

@testable import StripePaymentSheet
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
        XCTAssertNil(embeddedView.selectedRowButton)

        // Simulate tapping Cash App and verify delegate is called
        embeddedView.didTap(rowButton: embeddedView.getRowButton(accessibilityIdentifier: "Cash App Pay"))
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection, .didTapPaymentMethodRow])
        XCTAssertEqual(embeddedView.selectedRowButton?.type, .new(paymentMethodType: .stripe(.cashApp)), "Cash App Pay should be the current selection")
        mockDelegate.calls = []

        // Simulate tapping Klarna and verify delegate is called
        embeddedView.didTap(rowButton: embeddedView.getRowButton(accessibilityIdentifier: "Klarna"))
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection, .didTapPaymentMethodRow])
        XCTAssertEqual(embeddedView.selectedRowButton?.type, .new(paymentMethodType: .stripe(.klarna)), "Klarna should be the current selection")
        mockDelegate.calls = []

        // Resetting selection to last selection...
        embeddedView.resetSelectionToLastSelection()
        // ...should go back to Cash App
        XCTAssertEqual(embeddedView.selectedRowButton?.type, .new(paymentMethodType: .stripe(.cashApp)))
        // ...and call/not call the various delegate methods
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection])
        mockDelegate.calls = []

        // Resetting...
        embeddedView.resetSelection()
        // ...should go to nil
        XCTAssertNil(embeddedView.selectedRowButton)
        // ...and call/not call the various delegate methods
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection, ])
        mockDelegate.calls = []

        // Simulate tapping PayPal and verify delegate is called
        embeddedView.didTap(rowButton: embeddedView.getRowButton(accessibilityIdentifier: "PayPal"))
        XCTAssertEqual(mockDelegate.calls, [.didUpdateHeight, .didUpdateSelection, .didTapPaymentMethodRow])
        XCTAssertEqual(embeddedView.selectedRowButton?.type, .new(paymentMethodType: .stripe(.payPal)), "PayPal should be the current selection")
        mockDelegate.calls = []

        // Simulate tapping PayPal again (same selection) and verify delegate is NOT called
        embeddedView.didTap(rowButton: embeddedView.getRowButton(accessibilityIdentifier: "PayPal"))
        XCTAssertEqual(mockDelegate.calls, [.didTapPaymentMethodRow])
        XCTAssertEqual(embeddedView.selectedRowButton?.type, .new(paymentMethodType: .stripe(.payPal)), "PayPal should still be the current selection")
    }

    func testEmbeddedPaymentMethodsView_delegateTest_shouldAlwaysSetMandateTextEvenIfHidden() {
        let mockMandateProvider = MockMandateProvider { paymentMethodType in
            switch paymentMethodType {
            case .stripe(.cashApp):
                let s = String(repeating: "This is a long mandate text. ", count: 20)
                return NSAttributedString(string: s)
            case .stripe(.payPal):
                let s = String(repeating: "This is a long mandate text. ", count: 10)
                return NSAttributedString(string: s)
            case .stripe(.amazonPay):
                let s = String(repeating: "This is a long mandate text. ", count: 3)
                return NSAttributedString(string: s)
            default:
                return nil
            }
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
            mandateProvider: mockMandateProvider,
            shouldShowMandate: false
        )
        embeddedView.delegate = mockDelegate
        embeddedView.autosizeHeight(width: 300)

        // 1) Cash App
        let cashBtn = embeddedView.getRowButton(accessibilityIdentifier: "Cash App Pay")
        embeddedView.didTap(rowButton: cashBtn)
        XCTAssertEqual(mockDelegate.calls, [.didUpdateSelection, .didTapPaymentMethodRow])
        let expectedCash = String(repeating: "This is a long mandate text. ", count: 20)
        XCTAssertEqual(embeddedView.mandateText?.string, expectedCash)
        XCTAssertTrue(embeddedView.mandateText?.string.count == expectedCash.count)
        mockDelegate.calls = []

        // 2) Klarna (no mandate provider → nil)
        let klarnaBtn = embeddedView.getRowButton(accessibilityIdentifier: "Klarna")
        embeddedView.didTap(rowButton: klarnaBtn)
        XCTAssertEqual(mockDelegate.calls, [.didUpdateSelection, .didTapPaymentMethodRow])
        XCTAssertNil(embeddedView.mandateText)  // Klarna mandate provider returns nil
        mockDelegate.calls = []

        // 3) PayPal
        let paypalBtn = embeddedView.getRowButton(accessibilityIdentifier: "PayPal")
        embeddedView.didTap(rowButton: paypalBtn)
        XCTAssertEqual(mockDelegate.calls, [.didUpdateSelection, .didTapPaymentMethodRow])
        let expectedPayPal = String(repeating: "This is a long mandate text. ", count: 10)
        XCTAssertEqual(embeddedView.mandateText?.string, expectedPayPal)
        mockDelegate.calls = []

        // 4) Tap PayPal again (same selection)
        embeddedView.didTap(rowButton: paypalBtn)
        XCTAssertEqual(mockDelegate.calls, [.didTapPaymentMethodRow])
        // still the same text
        XCTAssertEqual(embeddedView.mandateText?.string, expectedPayPal)
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

    func shouldAnimateOnPress(_ paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool {
        return false
    }
}
