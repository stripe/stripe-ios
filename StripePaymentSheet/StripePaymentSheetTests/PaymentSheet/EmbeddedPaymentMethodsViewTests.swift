//
//  EmbeddedPaymentMethodsViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/4/24.
//

@_spi(EmbeddedPaymentElementPrivateBeta) @testable import StripePaymentSheet
import XCTest

final class EmbeddedPaymentMethodsViewTests: XCTestCase {

    // MARK: EmbeddedPaymentMethodsViewDelegate.heightDidChange test

    func testEmbeddedPaymentMethodsView_heightDidChange() {
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
        // Height did change should not be called after init
        XCTAssertFalse(mockDelegate.didCallHeightDidChange)

        // Simulate tapping Cash App
        embeddedView.didTap(selectedRowButton: rowButtons[1], selection: .new(paymentMethodType: .stripe(.cashApp)))
        XCTAssertTrue(mockDelegate.didCallHeightDidChange)
        mockDelegate.reset()

        // Simulate tapping Klarna
        embeddedView.didTap(selectedRowButton: rowButtons[2], selection: .new(paymentMethodType: .stripe(.klarna)))
        XCTAssertTrue(mockDelegate.didCallHeightDidChange)
        mockDelegate.reset()

        // Simulate tapping PayPal
        embeddedView.didTap(selectedRowButton: rowButtons[3], selection: .new(paymentMethodType: .stripe(.payPal)))
        XCTAssertTrue(mockDelegate.didCallHeightDidChange)
        mockDelegate.reset()

        // Simulate tapping PayPal again
        embeddedView.didTap(selectedRowButton: rowButtons[3], selection: .new(paymentMethodType: .stripe(.payPal)))
        XCTAssertFalse(mockDelegate.didCallHeightDidChange)
    }

}

private class MockEmbeddedPaymentMethodsViewDelegate: EmbeddedPaymentMethodsViewDelegate {

    private(set) var didCallHeightDidChange = false

    func heightDidChange() {
        didCallHeightDidChange = true
    }

    func reset() {
        didCallHeightDidChange = false
    }
}
