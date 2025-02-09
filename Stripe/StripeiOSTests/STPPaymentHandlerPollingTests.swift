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

    func mockedTimeTestStrategy(_ timeDelayInMillseconds: Int) -> TimeTestStrategy {
        return { _, retryCount, timeBetweenPollingAttemptsInt, maxRetries in
            // Instead of using wallClock time, calculate the time waited based on the attempt number & number of attempts.

            // Example 2: Fast Network
            // retryCount == 5
            // timeBetweenPollingAttemptsInt == 3
            // timeDelayInMillseconds == 80

            // Attempt Number 0: (0 * 3 * 1000) + (0 * 80) = 0
            // Attempt Number 1: (1 * 3 * 1000) + (1 * 80) = 3080
            // Attempt Number 2: (2 * 3 * 1000) + (2 * 80) = 6160
            // Attempt Number 3: (3 * 3 * 1000) + (3 * 80) = 9240
            // Attempt Number 4: (4 * 3 * 1000) + (4 * 80) = 12320

            // Example 2: Slow Network
            // retryCount == 5
            // timeBetweenPollingAttemptsInt == 3
            // timeDelayInMillseconds == 2000

            // Attempt Number 0: (0 * 3 * 1000) + (0 * 2000) = 0
            // Attempt Number 1: (1 * 3 * 1000) + (1 * 2000) = 5000
            // Attempt Number 2: (2 * 3 * 1000) + (2 * 2000) = 10000
            // Attempt Number 3: (3 * 3 * 1000) + (3 * 2000) = 15000

            let attemptNumber = maxRetries - retryCount
            return (attemptNumber * timeBetweenPollingAttemptsInt * 1000) + (attemptNumber * timeDelayInMillseconds)
        }
    }

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
            // Each STPPaymentHandler fetches, respond with a PI that requiresAction to force another poll
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
            // After we have exhausted polling, assert that the PI is canceled and still requires action
            XCTAssertEqual(STPPaymentHandlerActionStatus.canceled, status)
            XCTAssertEqual(.requiresAction, intent?.status)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        currentAction.setPollingStartTime(with: Date(), maxRetries: 5, timeTestStrategy: mockedTimeTestStrategy(80))

        let paymentHandler = STPPaymentHandlerMocked(apiClient: apiClientMock)
        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction)

        wait(for: [expectation])
        XCTAssertEqual(5, paymentHandler.numRetries)
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
        currentAction.setPollingStartTime(with: Date(), maxRetries: 5, timeTestStrategy: mockedTimeTestStrategy(2000))

        let paymentHandler = STPPaymentHandlerMocked(apiClient: apiClientMock)
        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction)

        wait(for: [expectation])
        XCTAssertEqual(3, paymentHandler.numRetries)
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
        currentAction.setPollingStartTime(with: Date(), maxRetries: 5, timeTestStrategy: STPPaymentHandler.defaultTimeTestStrategy())

        let paymentHandler = STPPaymentHandler(apiClient: apiClientMock)
        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction)

        wait(for: [expectation])
        XCTAssertEqual(6, numberOfTimesCalled)
    }
}

class STPPaymentHandlerMocked: STPPaymentHandler {
    var numRetries: Int = 0
    override func _retryAfterDelay(retryCount: Int, delayTime: TimeInterval = 3, block: @escaping STPVoidBlock) {
        numRetries += 1

        DispatchQueue.main.asyncAfter(deadline: .now()) {
            block()
        }
    }
}
