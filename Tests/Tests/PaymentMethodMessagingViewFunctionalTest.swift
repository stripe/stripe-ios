//
//  PaymentMethodMessagingViewFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 9/28/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP)@testable import Stripe
@_spi(STP)@testable import StripeCore
@_spi(STP)@testable import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentsUI
import XCTest

class PaymentMethodMessagingViewFunctionalTest: STPNetworkStubbingTestCase {
    let mockAnalyticsClient = MockAnalyticsClient()

    override func setUp() {
//        recordingMode = true
        super.setUp()
        mockAnalyticsClient.reset()
        PaymentMethodMessagingView.analyticsClient = mockAnalyticsClient
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
    }

    func testCreatesViewFromServerResponse() {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let config = PaymentMethodMessagingView.Configuration(
            apiClient: apiClient,
            paymentMethods: PaymentMethodMessagingView.Configuration.PaymentMethod.allCases,
            currency: "USD",
            amount: 1099
        )
        let createViewExpectation = expectation(description: "")
        PaymentMethodMessagingView.create(configuration: config) { result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success(let view):
                // We can't snapshot test the real view, since its appearance can change
                XCTAssertTrue(view.label.attributedText?.length ?? 0 > 0)
                XCTAssertTrue(
                    self.mockAnalyticsClient.productUsage.contains(
                        PaymentMethodMessagingView.stp_analyticsIdentifier
                    )
                )
                XCTAssertTrue(
                    self.mockAnalyticsClient.loggedAnalytics.contains { analytic in
                        analytic.event == .paymentMethodMessagingViewLoadSucceeded
                    }
                )
            }
            createViewExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testInitializingWithBadConfigurationReturnsError() {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let config = PaymentMethodMessagingView.Configuration(
            apiClient: apiClient,
            paymentMethods: [.klarna],
            currency: "FOO",
            amount: -100
        )
        let createViewExpectation = expectation(description: "")
        PaymentMethodMessagingView.create(configuration: config) { result in
            guard case .failure = result else {
                XCTFail()
                return
            }
            XCTAssertTrue(
                self.mockAnalyticsClient.loggedAnalytics.contains { analytic in
                    analytic.event == .paymentMethodMessagingViewLoadFailed
                }
            )
            createViewExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
