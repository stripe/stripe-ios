//
//  PaymentMethodMessagingViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 9/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentsUI
import UIKit

@MainActor
class PaymentMethodMessagingViewSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//                self.recordMode = true
    }

    /// - Note: This mock HTML should include all HTML tags the server can send down
    let mockHTML =
        """
        <img src=\"https://cdn.glitch.global/2d9cc690-78ea-45e5-9a44-bb3f3d2128a0/afterpay_logo_black.png?v=1666388884862\"><img src=\"https://cdn.glitch.global/2d9cc690-78ea-45e5-9a44-bb3f3d2128a0/klarna_logo_black.png?v=1666388884862\">
        <br/>
        As low as 4 <i>interest-free</i> payments of <b> $24.75 </b> 🎉
        """
    var configuration: PaymentMethodMessagingView.Configuration {
        return .init(paymentMethods: [.afterpayClearpay, .klarna], currency: "USD", amount: 100)
    }

    func testDefaults() async {
        guard
            let mockAttributedString = try? await PaymentMethodMessagingView.makeAttributedString(
                from: mockHTML,
                configuration: configuration
            )
        else {
            XCTFail()
            return
        }
        let view = PaymentMethodMessagingView(
            attributedString: mockAttributedString,
            modalURL: "https://stripe.com",
            configuration: configuration
        )
        verify(view)
    }

    func testCustomFontAndCustomTextColor() async {
        var configuration = configuration
        configuration.font = UIFont(name: "AmericanTypewriter", size: 10)!
        configuration.textColor = .darkGray
        guard
            let mockAttributedString = try? await PaymentMethodMessagingView.makeAttributedString(
                from: self.mockHTML,
                configuration: configuration
            )
        else {
            XCTFail()
            return
        }
        let view = PaymentMethodMessagingView(
            attributedString: mockAttributedString,
            modalURL: "https://stripe.com",
            configuration: configuration
        )
        verify(view)
    }

    // Remove _ to snapshot a view using the production endpoint
    // We can't test this, even if we stub the network response, because the response contains image URLs
    func _testReal() {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let config = PaymentMethodMessagingView.Configuration(
            apiClient: apiClient,
            paymentMethods: PaymentMethodMessagingView.Configuration.PaymentMethod.allCases,
            currency: "USD",
            amount: 1099
        )
        let createViewExpectation = expectation(description: "")
        PaymentMethodMessagingView.create(configuration: config) { [weak self] result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success(let view):
                self?.verify(view)
            }
            createViewExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

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
