//
//  EmbeddedPaymentMethodsViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/4/24.
//

@_spi(EmbeddedPaymentElementPrivateBeta) @testable import StripePaymentSheet
import XCTest

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

        // Simulate tapping Cash App and verify delegate is called
        embeddedView.didTap(selectedRowButton: rowButtons[1], selection: .new(paymentMethodType: .stripe(.cashApp)))
        XCTAssertTrue(mockDelegate.didCallSelectionDidUpdate, "selectionDidUpdate should be called when selection changes")
        XCTAssertEqual(
            mockDelegate.updatedSelection,
            .new(paymentMethodType: .stripe(.cashApp)),
            "selectionDidUpdate should receive the correct selection"
        )
        mockDelegate.resetAll()

        // Simulate tapping Klarna and verify delegate is called
        embeddedView.didTap(selectedRowButton: rowButtons[2], selection: .new(paymentMethodType: .stripe(.klarna)))
        XCTAssertTrue(mockDelegate.didCallSelectionDidUpdate, "selectionDidUpdate should be called when selection changes")
        XCTAssertEqual(
            mockDelegate.updatedSelection,
            .new(paymentMethodType: .stripe(.klarna)),
            "selectionDidUpdate should receive the correct selection"
        )
        mockDelegate.resetAll()

        // Simulate tapping PayPal and verify delegate is called
        embeddedView.didTap(selectedRowButton: rowButtons[3], selection: .new(paymentMethodType: .stripe(.payPal)))
        XCTAssertTrue(mockDelegate.didCallSelectionDidUpdate, "selectionDidUpdate should be called when selection changes")
        XCTAssertEqual(
            mockDelegate.updatedSelection,
            .new(paymentMethodType: .stripe(.payPal)),
            "selectionDidUpdate should receive the correct selection"
        )
        mockDelegate.resetAll()

        // Simulate tapping PayPal again (same selection) and verify delegate is NOT called
        embeddedView.didTap(selectedRowButton: rowButtons[3], selection: .new(paymentMethodType: .stripe(.payPal)))
        XCTAssertFalse(mockDelegate.didCallSelectionDidUpdate, "selectionDidUpdate should not be called when the same selection is selected again")
    }

}

private class MockEmbeddedPaymentMethodsViewDelegate: EmbeddedPaymentMethodsViewDelegate {
    
    // Existing properties
    private(set) var didCallHeightDidChange = false
    
    // New properties for selectionDidUpdate
    private(set) var didCallSelectionDidUpdate = false
    private(set) var updatedSelection: StripePaymentSheet.EmbeddedPaymentMethodsView.Selection?
    
    // MARK: - Delegate Methods
    
    func heightDidChange() {
        didCallHeightDidChange = true
    }
    
    func selectionDidUpdate(_ selection: StripePaymentSheet.EmbeddedPaymentMethodsView.Selection?) {
        didCallSelectionDidUpdate = true
        updatedSelection = selection
    }
    
    // MARK: - Reset Methods
    
    func resetHeightDidChange() {
        didCallHeightDidChange = false
    }
    
    func resetSelectionDidUpdate() {
        didCallSelectionDidUpdate = false
        updatedSelection = nil
    }
    
    func resetAll() {
        resetHeightDidChange()
        resetSelectionDidUpdate()
    }
}
