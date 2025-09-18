//
//  PollingBudgetTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/11/25.
//

@testable@_spi(STP) import StripePayments
import XCTest

final class PollingBudgetTests: XCTestCase {

    // MARK: - PollingBudget Initialization Tests

    func testPollingBudget_initializationWithCardPaymentMethod() {
        let budget = PollingBudget(startDate: Date(), paymentMethodType: .card)

        XCTAssertNotNil(budget)
        XCTAssertTrue(budget!.canPoll)
    }

    func testPollingBudget_initializationLPMs() {
        let paymentMethodTypes: [STPPaymentMethodType] = [.amazonPay, .revolutPay, .swish, .twint, .przelewy24]

        for type in paymentMethodTypes {
            let budget = PollingBudget(startDate: Date(), paymentMethodType: type)
            XCTAssertNotNil(budget, "Should create budget for \(type)")
            XCTAssertTrue(budget!.canPoll, "Should allow polling initially for \(type)")
        }
    }

    func testPollingBudget_initializationWithUnsupportedPaymentMethod() {
        let unsupportedTypes: [STPPaymentMethodType] = [.alipay, .iDEAL, .payPal, .unknown]

        for type in unsupportedTypes {
            let budget = PollingBudget(startDate: Date(), paymentMethodType: type)
            XCTAssertNil(budget, "Should return nil for unsupported payment method: \(type)")
        }
    }

    func testPollingBudget_initializationWithCustomDuration() {
        let budget = PollingBudget(startDate: Date(), duration: 3.0)
        XCTAssertTrue(budget.canPoll)
    }

    // MARK: - PollingBudget Behavior Tests

    func testPollingBudget_canPollBeforeStarting() {
        let budget = PollingBudget(startDate: Date(), duration: 1.0)
        XCTAssertTrue(budget.canPoll)
    }

    func testPollingBudget_recordPollAttemptWithinBudget() {
        let budget = PollingBudget(startDate: Date(), duration: 1.5)
        let expectation = XCTestExpectation(description: "Poll attempt within budget")

        budget.pollAfter {
            XCTAssertTrue(budget.canPoll)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testPollingBudget_budgetExhaustion() {
        let budget = PollingBudget(startDate: Date(), duration: 0.01)

        Thread.sleep(forTimeInterval: 0.02)

        XCTAssertTrue(budget.canPoll, "Should allow one poll even after budget expires")

        let expectation = XCTestExpectation(description: "Budget exhaustion")
        budget.pollAfter {
            XCTAssertFalse(budget.canPoll, "Should not allow polling after recording attempt beyond budget")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - "One Final Poll" Behavior Tests

    func testPollingBudget_oneFinalPollBehavior() {
        let budget = PollingBudget(startDate: Date(), duration: 0.01)

        Thread.sleep(forTimeInterval: 0.05)

        XCTAssertTrue(budget.canPoll, "Should allow the final poll even well beyond budget expiration")

        let expectation = XCTestExpectation(description: "Final poll")
        budget.pollAfter {
            XCTAssertFalse(budget.canPoll, "Should not allow further polling after final poll attempt")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(budget.canPoll, "Should remain false on subsequent checks")
    }

    func testPollingBudget_multiplePollsWithinBudget() {
        let budget = PollingBudget(startDate: Date(), duration: 3.0)

        XCTAssertTrue(budget.canPoll)
        let expectation1 = XCTestExpectation(description: "First poll")
        budget.pollAfter {
            XCTAssertTrue(budget.canPoll)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)

        let expectation2 = XCTestExpectation(description: "Second poll")
        budget.pollAfter {
            XCTAssertTrue(budget.canPoll)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)

        Thread.sleep(forTimeInterval: 2.0)

        // After the time has expired, canPoll should still be true (allowing one final poll)
        // But once we call pollAfter, it should detect the budget is exhausted and set canPoll to false
        XCTAssertTrue(budget.canPoll, "Should allow final poll after expiration")
        let expectation3 = XCTestExpectation(description: "Final poll after expiration")
        budget.pollAfter {
            XCTAssertFalse(budget.canPoll, "Should not allow polling after final attempt")
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 1.0)
    }

    func testPollingBudget_withCardPaymentMethodDuration() {
        let budget = PollingBudget(startDate: Date(), paymentMethodType: .card)!

        XCTAssertTrue(budget.canPoll)

        let expectation = XCTestExpectation(description: "Card payment method poll")
        budget.pollAfter {
            XCTAssertTrue(budget.canPoll)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testPollingBudget_withWalletPaymentMethodDuration() {
        let budget = PollingBudget(startDate: Date(), paymentMethodType: .amazonPay)!

        XCTAssertTrue(budget.canPoll)

        let expectation = XCTestExpectation(description: "LPM payment method poll")
        budget.pollAfter {
            XCTAssertTrue(budget.canPoll)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Edge Cases

    func testPollingBudget_pastStartDate() {
        let pastDate = Date(timeIntervalSinceNow: -10)
        let budget = PollingBudget(startDate: pastDate, duration: 0.01)

        XCTAssertTrue(budget.canPoll)

        let expectation = XCTestExpectation(description: "Past start date poll")
        budget.pollAfter {
            XCTAssertFalse(budget.canPoll)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPollingBudget_veryShortDuration() {
        let budget = PollingBudget(startDate: Date(), duration: 0.001)

        Thread.sleep(forTimeInterval: 0.01)
        XCTAssertTrue(budget.canPoll)

        let expectation = XCTestExpectation(description: "Very short duration poll")
        budget.pollAfter {
            XCTAssertFalse(budget.canPoll)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Timing Optimization Tests

    func testPollAfter_firstPollTiming() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)
        let expectation = XCTestExpectation(description: "First poll should execute after 1 second")

        let startTime = Date()
        budget.pollAfter {
            let elapsed = Date().timeIntervalSince(startTime)
            XCTAssertGreaterThan(elapsed, 0.95, "Should wait close to 1 second for first poll")
            XCTAssertLessThan(elapsed, 1.1, "Should not wait much longer than 1 second")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testPollAfter_fastRequestTiming() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)
        let expectation = XCTestExpectation(description: "Fast request should respect 1-second intervals")

        // Record a poll attempt and wait a short time
        let initialExpectation = XCTestExpectation(description: "Initial poll")
        budget.pollAfter {
            initialExpectation.fulfill()
        }
        wait(for: [initialExpectation], timeout: 2.0)
        Thread.sleep(forTimeInterval: 0.3)

        let startTime = Date()
        budget.pollAfter {
            let elapsed = Date().timeIntervalSince(startTime)
            // Should wait remaining time (~0.7 seconds)
            XCTAssertGreaterThan(elapsed, 0.6, "Should wait for remaining time")
            XCTAssertLessThan(elapsed, 0.8, "Should not wait too long")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testPollAfter_slowRequestTiming() {
        let budget = PollingBudget(startDate: Date(), duration: 3.0)
        let expectation = XCTestExpectation(description: "Slow request should poll immediately")

        // Record a poll attempt and wait longer than target interval
        let initialExpectation = XCTestExpectation(description: "Initial slow poll")
        budget.pollAfter {
            initialExpectation.fulfill()
        }
        wait(for: [initialExpectation], timeout: 2.0)
        Thread.sleep(forTimeInterval: 1.1)

        let startTime = Date()
        budget.pollAfter {
            let elapsed = Date().timeIntervalSince(startTime)
            // Should poll immediately (or very quickly)
            XCTAssertLessThan(elapsed, 0.1, "Should poll immediately when last poll was > 1 second ago")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testPollAfter_multipleQuickPolls() {
        let budget = PollingBudget(startDate: Date(), duration: 3.0)
        let expectation = XCTestExpectation(description: "Multiple quick polls should respect timing")
        expectation.expectedFulfillmentCount = 3

        var pollTimes: [TimeInterval] = []
        let overallStart = Date()

        func performPoll(_ pollNumber: Int) {
            let pollStart = Date()
            budget.pollAfter {
                pollTimes.append(Date().timeIntervalSince(overallStart))

                if pollNumber < 3 {
                    // Simulate quick network response
                    Thread.sleep(forTimeInterval: 0.1)
                    performPoll(pollNumber + 1)
                }

                expectation.fulfill()
            }
        }

        performPoll(1)
        wait(for: [expectation], timeout: 5.0)

        // Verify that polls are spaced approximately 1 second apart
        if pollTimes.count >= 2 {
            let secondPollGap = pollTimes[1] - pollTimes[0]
            XCTAssertGreaterThan(secondPollGap, 0.9, "Second poll should wait ~1 second after first")
            XCTAssertLessThan(secondPollGap, 1.2, "Second poll should not wait much more than 1 second")
        }

        if pollTimes.count >= 3 {
            let thirdPollGap = pollTimes[2] - pollTimes[1]
            XCTAssertGreaterThan(thirdPollGap, 0.9, "Third poll should wait ~1 second after second")
            XCTAssertLessThan(thirdPollGap, 1.2, "Third poll should not wait much more than 1 second")
        }
    }
}
