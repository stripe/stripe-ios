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
        let budget = PollingBudget(startDate: Date(), duration: 1.0)

        budget.recordPollAttempt()
        XCTAssertTrue(budget.canPoll)
    }

    func testPollingBudget_budgetExhaustion() {
        let budget = PollingBudget(startDate: Date(), duration: 0.01)

        Thread.sleep(forTimeInterval: 0.02)

        XCTAssertTrue(budget.canPoll, "Should allow one poll even after budget expires")

        budget.recordPollAttempt()
        XCTAssertFalse(budget.canPoll, "Should not allow polling after recording attempt beyond budget")
    }

    // MARK: - "One Final Poll" Behavior Tests

    func testPollingBudget_oneFinalPollBehavior() {
        let budget = PollingBudget(startDate: Date(), duration: 0.01)

        Thread.sleep(forTimeInterval: 0.05)

        XCTAssertTrue(budget.canPoll, "Should allow the final poll even well beyond budget expiration")

        budget.recordPollAttempt()
        XCTAssertFalse(budget.canPoll, "Should not allow further polling after final poll attempt")
        XCTAssertFalse(budget.canPoll, "Should remain false on subsequent checks")
    }

    func testPollingBudget_multiplePollsWithinBudget() {
        let budget = PollingBudget(startDate: Date(), duration: 0.1)

        XCTAssertTrue(budget.canPoll)
        budget.recordPollAttempt()
        XCTAssertTrue(budget.canPoll)
        budget.recordPollAttempt()
        XCTAssertTrue(budget.canPoll)

        Thread.sleep(forTimeInterval: 0.12)

        XCTAssertTrue(budget.canPoll, "Should allow final poll after expiration")
        budget.recordPollAttempt()
        XCTAssertFalse(budget.canPoll, "Should not allow polling after final attempt")
    }

    func testPollingBudget_withCardPaymentMethodDuration() {
        let budget = PollingBudget(startDate: Date(), paymentMethodType: .card)!

        XCTAssertTrue(budget.canPoll)

        budget.recordPollAttempt()
        XCTAssertTrue(budget.canPoll)
    }

    func testPollingBudget_withWalletPaymentMethodDuration() {
        let budget = PollingBudget(startDate: Date(), paymentMethodType: .amazonPay)!

        XCTAssertTrue(budget.canPoll)

        budget.recordPollAttempt()
        XCTAssertTrue(budget.canPoll)
    }

    func testPollingBudget_behaviorConsistency() {
        let budget1 = PollingBudget(startDate: Date(), duration: 0.01)
        let budget2 = PollingBudget(startDate: Date(), duration: 0.01)

        Thread.sleep(forTimeInterval: 0.02)

        XCTAssertEqual(budget1.canPoll, budget2.canPoll)

        budget1.recordPollAttempt()
        budget2.recordPollAttempt()

        XCTAssertEqual(budget1.canPoll, budget2.canPoll)
    }

    // MARK: - Edge Cases

    func testPollingBudget_pastStartDate() {
        let pastDate = Date(timeIntervalSinceNow: -10)
        let budget = PollingBudget(startDate: pastDate, duration: 0.01)

        XCTAssertTrue(budget.canPoll)

        budget.recordPollAttempt()
        XCTAssertFalse(budget.canPoll)
    }

    func testPollingBudget_veryShortDuration() {
        let budget = PollingBudget(startDate: Date(), duration: 0.001)

        Thread.sleep(forTimeInterval: 0.01)
        XCTAssertTrue(budget.canPoll)

        budget.recordPollAttempt()
        XCTAssertFalse(budget.canPoll)
    }

    // MARK: - Timing Optimization Tests

    func testRecommendedDelay_firstPoll() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)

        // For the first poll with no previous attempt, should return the target interval
        let delay = budget.recommendedDelay(targetInterval: 1.5)
        XCTAssertEqual(delay, 1.5, accuracy: 0.01, "First poll should return target interval")

        // Test default target interval
        let defaultDelay = budget.recommendedDelay()
        XCTAssertEqual(defaultDelay, 1.0, accuracy: 0.01, "Default target interval should be 1.0")
    }

    func testRecommendedDelay_fastRequest() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)

        // Record a poll attempt and wait a short time
        budget.recordPollAttempt()
        Thread.sleep(forTimeInterval: 0.3)

        // Should return remaining time until target interval
        let delay = budget.recommendedDelay(targetInterval: 1.0)
        XCTAssertGreaterThan(delay, 0.6, "Should wait for remaining time")
        XCTAssertLessThan(delay, 0.8, "Should not wait too long")
    }

    func testRecommendedDelay_slowRequest() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)

        // Record a poll attempt and wait longer than target interval
        budget.recordPollAttempt()
        Thread.sleep(forTimeInterval: 1.1)

        // Should return 0 (immediate polling)
        let delay = budget.recommendedDelay(targetInterval: 1.0)
        XCTAssertEqual(delay, 0.0, accuracy: 0.01, "Should poll immediately when last poll was > target interval ago")
    }

    func testRecommendedDelay_exactTargetInterval() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)

        // Record a poll attempt and wait exactly the target interval
        budget.recordPollAttempt()
        Thread.sleep(forTimeInterval: 1.0)

        // Should return 0 or very close to 0
        let delay = budget.recommendedDelay(targetInterval: 1.0)
        XCTAssertLessThanOrEqual(delay, 0.05, "Should poll immediately or very soon when exactly at target interval")
    }

    func testRecommendedDelay_customTargetInterval() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)

        // Test with 2.0 second target interval
        budget.recordPollAttempt()
        Thread.sleep(forTimeInterval: 0.5)

        let delay = budget.recommendedDelay(targetInterval: 2.0)
        XCTAssertGreaterThan(delay, 1.4, "Should wait for remaining time with custom interval")
        XCTAssertLessThan(delay, 1.6, "Should not wait too long with custom interval")
    }

    func testLastPollAttempt_initialState() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)

        // Initially, lastPollAttempt should be nil (tested indirectly via recommendedDelay)
        let delay = budget.recommendedDelay(targetInterval: 2.5)
        XCTAssertEqual(delay, 2.5, accuracy: 0.01, "Should return full target interval when no previous poll recorded")
    }

    func testLastPollAttempt_updatesOnRecord() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)

        // Record first attempt and wait a bit
        budget.recordPollAttempt()
        Thread.sleep(forTimeInterval: 0.3)
        let firstDelay = budget.recommendedDelay(targetInterval: 1.0)

        // Record second attempt immediately (should reset the timer)
        budget.recordPollAttempt()
        let secondDelay = budget.recommendedDelay(targetInterval: 1.0)

        // Second delay should be close to full interval since we just recorded a new attempt
        XCTAssertGreaterThan(secondDelay, 0.95, "Should wait almost full interval after recording new poll attempt")
        XCTAssertLessThan(firstDelay, 0.8, "First delay should be less since time had passed")
        XCTAssertGreaterThan(secondDelay, firstDelay, "Second delay should be greater than first (timer was reset)")
    }

    func testPollingBudget_timingOptimizationIntegration() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)

        // Simulate first poll - should wait full interval
        let firstDelay = budget.recommendedDelay()
        XCTAssertEqual(firstDelay, 1.0, accuracy: 0.01, "First poll should wait full interval")

        // Record poll and simulate fast response (0.2s)
        budget.recordPollAttempt()
        Thread.sleep(forTimeInterval: 0.2)
        let fastDelay = budget.recommendedDelay()
        XCTAssertGreaterThan(fastDelay, 0.7, "Should wait remaining time after fast response")
        XCTAssertLessThan(fastDelay, 0.9, "Should not wait too long after fast response")

        // Record poll and simulate slow response (1.2s)  
        budget.recordPollAttempt()
        Thread.sleep(forTimeInterval: 1.2)
        let slowDelay = budget.recommendedDelay()
        XCTAssertLessThanOrEqual(slowDelay, 0.05, "Should poll immediately after slow response")
    }

    func testPollingBudget_multipleQuickPolls() {
        let budget = PollingBudget(startDate: Date(), duration: 10.0)

        // Simulate multiple quick polls in succession
        for i in 0..<3 {
            budget.recordPollAttempt()
            Thread.sleep(forTimeInterval: 0.1) // Very fast "network requests"

            let delay = budget.recommendedDelay()
            XCTAssertGreaterThan(delay, 0.8, "Poll \(i): Should wait most of the interval after quick response")
            XCTAssertLessThan(delay, 1.0, "Poll \(i): Should wait less than full interval")
        }
    }
}
