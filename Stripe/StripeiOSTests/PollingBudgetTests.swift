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

    func testPollingBudget_initializationWithWalletPaymentMethods() {
        let walletTypes: [STPPaymentMethodType] = [.amazonPay, .revolutPay, .swish, .twint, .przelewy24]

        for type in walletTypes {
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

    // MARK: - Critical "One Final Poll" Behavior Tests

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

    // MARK: - Integration Tests

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
}
