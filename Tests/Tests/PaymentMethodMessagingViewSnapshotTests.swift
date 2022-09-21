//
//  PaymentMethodMessagingViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 9/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentsUI

class PaymentMethodMessagingViewSnapshotTests: FBSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        self.recordMode = true
    }
    
    /// - Note: This mock HTML should include all HTML tags the server can send down
    let mockHTML =
    """
    <img src=\"https://qa-b.stripecdn.com/payment-method-messaging-statics-srv/assets/klarna_logo_black.png\">&nbsp&nbsp<img src=\"https://qa-b.stripecdn.com/payment-method-messaging-statics-srv/assets/klarna_logo_black.png\">
    <br/>
    As low as 4 <i>interest-free</i> payments of <b> $24.75 </b> 🎉
    """
    private var window: UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 1026))
        window.isHidden = false
        return window
    }
    var configuration: PaymentMethodMessagingView.Configuration {
        return .init(paymentMethods: [.afterpayClearpay, .klarna], currency: "USD", amount: 100)
    }
    
    func makeMockAttributedString() -> NSAttributedString? {
        var mockAttributedString: NSAttributedString?
        let expectation = expectation(description: "")
        PaymentMethodMessagingView.makeAttributedString(from: mockHTML, font: configuration.font, textColor: configuration.textColor) { result in
            switch result {
            case .success(let attributedString):
                mockAttributedString = attributedString
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        return mockAttributedString
    }
    
    func testDefaults() {
        guard
            let mockAttributedString = makeMockAttributedString() else {
            XCTFail()
            return
        }
            let view = PaymentMethodMessagingView(attributedString: mockAttributedString, modalURL: "https://stripe.com", configuration: configuration)
       
        let stackView = UIStackView(arrangedSubviews: [view])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.addConstraint(stackView.widthAnchor.constraint(equalToConstant: 375))
        stackView.backgroundColor = .white
        
        stackView.setNeedsLayout()
        stackView.layoutIfNeeded()
        
        STPSnapshotVerifyView(stackView)
    }
    
//    @available(iOS 13.0, *)
//    func testDarkMode() {
//        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 1026))
//        window.isHidden = false
//        window.overrideUserInterfaceStyle = .dark
//        guard let view = try? PaymentMethodMessagingView(html: mockHTML, modalURL: "https://stripe.com", configuration: configuration) else {
//            XCTFail()
//            return
//        }
//        window.addSubview(view)
//        verify(view)
//    }
//
//    func testCustomFontAndCustomDarkColors() {
//        guard
//            let view = try? PaymentMethodMessagingView(html: mockHTML, modalURL: "https://stripe.com", configuration: configuration),
//            let font = UIFont(name: "AmericanTypewriter", size: 10)
//        else {
//            XCTFail()
//            return
//        }
//        view.font = font
//        view.backgroundColor = UIColor(white: 0.1, alpha: 1)
//        view.textColor = .lightGray
//        verify(view) // The images should be tinted white to match the text color
//    }
    
    // MARK: - Helpers
    
    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
