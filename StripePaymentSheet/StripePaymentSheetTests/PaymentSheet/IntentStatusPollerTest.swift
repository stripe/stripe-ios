@testable import StripePaymentSheet
import StripePaymentsTestUtils
import XCTest

class IntentStatusPollerTest: XCTestCase {
    var sut: IntentStatusPoller!
    var mockIntentRetriever: MockPaymentIntentRetriever!
    var mockDelegate: MockIntentStatusPollerDelegate!
    var intentRetrieverExpectation: XCTestExpectation!
    var delegateExpectation: XCTestExpectation!

    override func setUp() {
        super.setUp()
        mockIntentRetriever = MockPaymentIntentRetriever()
        mockDelegate = MockIntentStatusPollerDelegate()
        sut = IntentStatusPoller(retryInterval: 1.0, intentRetriever: mockIntentRetriever, clientSecret: "test_client_secret")
        sut.delegate = mockDelegate
    }

    override func tearDown() {
        sut = nil
        mockIntentRetriever = nil
        mockDelegate = nil
        super.tearDown()
    }

    func setExpectations(apiExpectedCount: Int, delegateExpectedCount: Int) {
        intentRetrieverExpectation = XCTestExpectation()
        delegateExpectation = XCTestExpectation()
        delegateExpectation.assertForOverFulfill = true
        intentRetrieverExpectation.expectedFulfillmentCount = apiExpectedCount
        delegateExpectation.expectedFulfillmentCount = delegateExpectedCount

        mockIntentRetriever.expectation =  intentRetrieverExpectation
        mockDelegate.expectation = delegateExpectation
    }

    func testPolling_beginSuspendBegin() {
        // Poll 3 times
        // Should call retrievePaymentIntent 3 times
        // Delegate should be notified on the first poll but not subsequent polls
        setExpectations(apiExpectedCount: 3, delegateExpectedCount: 1)
        mockIntentRetriever.mockedStatus = .requiresPaymentMethod

        sut.beginPolling()
        XCTAssertTrue(sut.isPolling)

        wait(for: [intentRetrieverExpectation, delegateExpectation], timeout: 5.0)
        XCTAssertEqual(mockDelegate.latestPaymentIntent?.status, .requiresPaymentMethod)

        sut.suspendPolling() // We should no longer notify the delegate or call the API
        XCTAssertFalse(sut.isPolling)

        // Make the API client return succeeded, then the delegate should NOT be notified, and API should NOT be called due to suspended polling
        setExpectations(apiExpectedCount: 1, delegateExpectedCount: 1)
        intentRetrieverExpectation.isInverted = true // expectations should not be fufilled since polling is suspended
        delegateExpectation.isInverted = true
        mockIntentRetriever.mockedStatus = .succeeded

        wait(for: [intentRetrieverExpectation, delegateExpectation], timeout: 5.0)
        // delegate should not have been notified of succeeded since polling was suspended
        XCTAssertEqual(mockDelegate.latestPaymentIntent?.status, .requiresPaymentMethod)

        // Resume polling
        setExpectations(apiExpectedCount: 1, delegateExpectedCount: 1)
        sut.beginPolling()
        XCTAssertTrue(sut.isPolling)

        wait(for: [intentRetrieverExpectation, delegateExpectation], timeout: 5.0)
        XCTAssertEqual(mockDelegate.latestPaymentIntent?.status, .succeeded)
    }

    func testPollOnce() {
        setExpectations(apiExpectedCount: 1, delegateExpectedCount: 1)
        mockIntentRetriever.mockedStatus = .requiresPaymentMethod

        sut.pollOnce()
        XCTAssertFalse(sut.isPolling)

        // API client should be called and delegate should be notified of the new status since updating from .unknown`
        wait(for: [intentRetrieverExpectation, delegateExpectation], timeout: 5.0)
        XCTAssertEqual(mockDelegate.latestPaymentIntent?.status, .requiresPaymentMethod)
    }
}

// Mock our PaymentIntentRetrievable for testing.
class MockPaymentIntentRetriever: PaymentIntentRetrievable {
    var expectation: XCTestExpectation?
    var mockedStatus: STPPaymentIntentStatus = .unknown

    func retrievePaymentIntent(withClientSecret clientSecret: String, completion: @escaping STPPaymentIntentCompletionBlock) {
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["card"], status: mockedStatus)

        expectation?.fulfill()
        completion(paymentIntent, nil)
    }
}

// Mock delegate
class MockIntentStatusPollerDelegate: IntentStatusPollerDelegate {
    var expectation: XCTestExpectation?
    var latestPaymentIntent: STPPaymentIntent?

    func didUpdate(paymentIntent: STPPaymentIntent) {
        self.latestPaymentIntent = paymentIntent
        self.expectation?.fulfill()
    }
}

