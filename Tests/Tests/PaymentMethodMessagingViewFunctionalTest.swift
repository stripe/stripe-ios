//
//  PaymentMethodMessagingViewFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 9/28/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripePaymentsUI

class PaymentMethodMessagingViewFunctionalTest: XCTestCase {
    func testCreatesViewFromServerResponse() {
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let config = PaymentMethodMessagingView.Configuration(apiClient: apiClient, paymentMethods: PaymentMethodMessagingView.Configuration.PaymentMethod.allCases, currency: "USD", amount: 1099)
        let createViewExpectation = expectation(description: "")
        PaymentMethodMessagingView.create(configuration: config) { result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success(let view):
                // We can't snapshot test the real view, since its appearance can change
                XCTAssertTrue(view.textView.attributedText.length > 0)
            }
            createViewExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testInitializingWithBadConfigurationReturnsError() {
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let config = PaymentMethodMessagingView.Configuration(apiClient: apiClient, paymentMethods: [.klarna], currency: "FOO", amount: -100)
        let createViewExpectation = expectation(description: "")
        PaymentMethodMessagingView.create(configuration: config) { result in
            guard case .failure = result else {
                XCTFail()
                return
            }
            createViewExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
