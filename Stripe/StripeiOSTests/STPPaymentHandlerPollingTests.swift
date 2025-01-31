//
//  STPPaymentHandlerPollingTests.swift
//  Stripe
//
//  Created by John Woo on 1/29/25.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import Stripe3DS2
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentHandlerPollingTests: XCTestCase {
    func testPaymentIntentPolls_withSimulatedFastNetwork() {
        let expectation = expectation(description: "")
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["amazon_pay"],
                                                      status: .requiresAction,
                                                      paymentMethod: [
                                                        "id": "pm_test",
                                                        "type": "amazon_pay",
                                                      ],
                                                      nextAction: .useStripeSDK)
        let onRetrievePaymentIntent: STPAPIClientMockPaymentCallback = { completion in
            let paymentMethod: [String: Any] = ["id": "pm_test", "type": "amazon_pay"]
            let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["amazon_pay"],
                                                          status: .requiresAction,
                                                          paymentMethod: paymentMethod,
                                                          nextAction: .redirectToURL)
            completion(paymentIntent, nil)
        }
        let apiClientMock = STPAPIClientMock(onRetrievePaymentIntent: onRetrievePaymentIntent)
        let currentAction = STPPaymentHandlerPaymentIntentActionParams.makeTestable(apiClient: apiClientMock,
                                                                                    paymentMethodTypes: ["card"],
                                                                                    paymentIntent: paymentIntent) { status, intent, error in
            XCTAssertEqual(STPPaymentHandlerActionStatus.canceled, status)
            XCTAssertEqual(.requiresAction, intent?.status)
            XCTAssertNil(error)
            expectation.fulfill()

        }
        currentAction.setPollingStartTime(with: Date(), maxRetries: 5, timeStrategy: .simluatedNetworkDelay(80))

        let paymentHandler = STPPaymentHandlerMocked(apiClient: apiClientMock)
        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction)

        wait(for: [expectation])
        XCTAssertEqual(5, paymentHandler.scheduledJobs.count)
    }
    func testPaymentIntentPolls_withSimulatedSlowNetwork() {
        let expectation = expectation(description: "")
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["amazon_pay"],
                                                              status: .requiresAction,
                                                              paymentMethod: [
                                                                "id": "pm_test",
                                                                "type": "amazon_pay",
                                                              ],
                                                              nextAction: .useStripeSDK)
        let onRetrievePaymentIntent: STPAPIClientMockPaymentCallback = { completion in
            let paymentMethod: [String: Any] = ["id": "pm_test", "type": "amazon_pay"]
            let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["amazon_pay"],
                                                          status: .requiresAction,
                                                          paymentMethod: paymentMethod,
                                                          nextAction: .redirectToURL)
            completion(paymentIntent, nil)
        }
        let apiClientMock = STPAPIClientMock(onRetrievePaymentIntent: onRetrievePaymentIntent)
        let currentAction = STPPaymentHandlerPaymentIntentActionParams.makeTestable(apiClient: apiClientMock,
                                                                                    paymentMethodTypes: ["card"],
                                                                                    paymentIntent: paymentIntent) { status, intent, error in
            XCTAssertEqual(STPPaymentHandlerActionStatus.canceled, status)
            XCTAssertEqual(.requiresAction, intent?.status)
            XCTAssertNil(error)
            expectation.fulfill()

        }
        currentAction.setPollingStartTime(with: Date(), maxRetries: 5, timeStrategy: .simluatedNetworkDelay(2000))

        let paymentHandler = STPPaymentHandlerMocked(apiClient: apiClientMock)
        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction)

        wait(for: [expectation])
        XCTAssertEqual(3, paymentHandler.scheduledJobs.count)
    }

    // This takes about 5*3 seconds to execute
    func testPaymentIntentPolls_realTime() {
        let expectation = expectation(description: "")
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["amazon_pay"],
                                                              status: .requiresAction,
                                                              paymentMethod: [
                                                                "id": "pm_test",
                                                                "type": "amazon_pay",
                                                              ],
                                                              nextAction: .useStripeSDK)
        var numberOfTimesCalled = 0
        let onRetrievePaymentIntent: STPAPIClientMockPaymentCallback = { completion in
            numberOfTimesCalled += 1
            let paymentMethod: [String: Any] = ["id": "pm_test", "type": "amazon_pay"]
            let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["amazon_pay"],
                                                          status: .requiresAction,
                                                          paymentMethod: paymentMethod,
                                                          nextAction: .redirectToURL)
            completion(paymentIntent, nil)
        }
        let apiClientMock = STPAPIClientMock(onRetrievePaymentIntent: onRetrievePaymentIntent)
        let currentAction = STPPaymentHandlerPaymentIntentActionParams.makeTestable(apiClient: apiClientMock,
                                                                                    paymentMethodTypes: ["card"],
                                                                                    paymentIntent: paymentIntent) { status, intent, error in
            XCTAssertEqual(STPPaymentHandlerActionStatus.canceled, status)
            XCTAssertEqual(.requiresAction, intent?.status)
            XCTAssertNil(error)
            expectation.fulfill()

        }
        // Note, there is zero network delay since network calls are mocked.
        currentAction.setPollingStartTime(with: Date(), maxRetries: 5, timeStrategy: .realTime)

        let paymentHandler = STPPaymentHandler(apiClient: apiClientMock)
        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction)

        wait(for: [expectation])
        XCTAssertEqual(6, numberOfTimesCalled)
    }
}

class STPPaymentHandlerMocked: STPPaymentHandler {
    var scheduledJobs: [DispatchTime] = []
    override func _retryAfterDelay(retryCount: Int, delayTime: TimeInterval = 3, block: @escaping STPVoidBlock) {

        let lastScheduledJob = scheduledJobs.first ?? .now()
        let nextScheduledJob = lastScheduledJob + delayTime
        scheduledJobs.append(nextScheduledJob)

        DispatchQueue.main.asyncAfter(deadline: .now()) {
            block()
        }
    }
}
