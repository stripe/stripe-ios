//
//  PollingBudgetTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/11/25.
//

@testable@_spi(STP) import StripePayments
import XCTest

final class PollingBudgetTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithSupportedPaymentMethods_CreatesBudgetWithCorrectDuration() {
        // Test 5-second budget payment methods
        let fiveSecondMethods: [STPPaymentMethodType] = [.amazonPay, .revolutPay, .swish, .twint, .przelewy24]
        for method in fiveSecondMethods {
            let budget = PollingBudget(paymentMethodType: method)
            XCTAssertNotNil(budget, "Should create budget for \(method)")
            XCTAssertEqual(budget?.maxDuration, 5.0, "Should have 5-second duration for \(method)")
        }

        // Test 15-second budget payment method
        let cardBudget = PollingBudget(paymentMethodType: .card)
        XCTAssertNotNil(cardBudget)
        XCTAssertEqual(cardBudget?.maxDuration, 15.0, "Card should have 15-second duration")
    }

    func testInit_WithUnsupportedPaymentMethods_ReturnsNil() {
        let unsupportedMethods: [STPPaymentMethodType] = [.alipay, .payPal, .klarna, .cashApp, .unknown]
        for method in unsupportedMethods {
            let budget = PollingBudget(paymentMethodType: method)
            XCTAssertNil(budget, "Should return nil for unsupported method \(method)")
        }
    }

    func testInit_WithExplicitDuration_SetsDurationCorrectly() {
        let budget = PollingBudget(duration: 10.0)
        XCTAssertEqual(budget.maxDuration, 10.0)
    }

    // MARK: - Budget State Tests

    func testHasBudgetRemaining_BeforeStart_ReturnsTrue() {
        let budget = PollingBudget(duration: 1.0)
        XCTAssertTrue(budget.hasBudgetRemaining, "Should have budget remaining before start")
    }

    func testHasBudgetRemaining_AfterStart_WithinBudget_ReturnsTrue() {
        let budget = PollingBudget(duration: 10.0)
        budget.start()
        XCTAssertTrue(budget.hasBudgetRemaining, "Should have budget remaining immediately after start")
    }

    func testHasBudgetRemaining_AfterInvalidate_ReturnsFalse() {
        let budget = PollingBudget(duration: 10.0)
        budget.start()
        budget.invalidate()
        XCTAssertFalse(budget.hasBudgetRemaining, "Should not have budget remaining after invalidate")
    }

    func testHasPolledFinal_InitiallyFalse_BecomesTrue() {
        let budget = PollingBudget(duration: 1.0)
        XCTAssertFalse(budget.hasPolledFinal, "hasPolledFinal should initially be false")

        budget.invalidate()
        XCTAssertTrue(budget.hasPolledFinal, "hasPolledFinal should be true after invalidate")
    }

    // MARK: - Timing Tests

    func testStart_SetsStartDate_AllowsMultipleCalls() {
        let budget = PollingBudget(duration: 5.0)

        budget.start()
        XCTAssertTrue(budget.hasBudgetRemaining, "Should have budget after first start")

        // Multiple calls to start() should not reset the timer
        budget.start()
        XCTAssertTrue(budget.hasBudgetRemaining, "Multiple start calls should be safe")
    }

    func testBudgetExpiration_WithVeryShortDuration() {
        let budget = PollingBudget(duration: 0.001) // 1ms
        budget.start()

        // Wait a bit to let the budget expire
        let expectation = self.expectation(description: "Budget should expire")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1)
        XCTAssertFalse(budget.hasBudgetRemaining, "Budget should be expired after short duration")
    }

    // MARK: - Integration Tests

    func testTypicalPollingFlow() {
        // Simulate a typical polling scenario
        let budget = PollingBudget(paymentMethodType: .swish)!

        // Initial state
        XCTAssertTrue(budget.hasBudgetRemaining, "Should have budget initially")
        XCTAssertFalse(budget.hasPolledFinal, "Should not have polled final initially")

        // Start polling
        budget.start()
        XCTAssertTrue(budget.hasBudgetRemaining, "Should have budget after start")

        // Simulate polling completion
        budget.invalidate()
        XCTAssertFalse(budget.hasBudgetRemaining, "Should not have budget after completion")
        XCTAssertTrue(budget.hasPolledFinal, "Should have polled final after completion")
    }

    func testPaymentMethodSpecificBudgets() {
        // Verify different payment methods get appropriate budgets
        let swishBudget = PollingBudget(paymentMethodType: .swish)!
        let cardBudget = PollingBudget(paymentMethodType: .card)!
        let amazonBudget = PollingBudget(paymentMethodType: .amazonPay)!

        XCTAssertEqual(swishBudget.maxDuration, 5.0, "Swish should get 5-second budget")
        XCTAssertEqual(cardBudget.maxDuration, 15.0, "Card should get 15-second budget")
        XCTAssertEqual(amazonBudget.maxDuration, 5.0, "Amazon Pay should get 5-second budget")

        // Verify they all start with budget available
        XCTAssertTrue(swishBudget.hasBudgetRemaining)
        XCTAssertTrue(cardBudget.hasBudgetRemaining)
        XCTAssertTrue(amazonBudget.hasBudgetRemaining)
    }

    // MARK: - Edge Cases

    func testInvalidate_BeforeStart_WorksCorrectly() {
        let budget = PollingBudget(duration: 5.0)
        budget.invalidate()
        XCTAssertFalse(budget.hasBudgetRemaining, "Should respect invalidation even before start")
        XCTAssertTrue(budget.hasPolledFinal, "hasPolledFinal should be true after invalidate")
    }

    func testMultipleInvalidate_Safe() {
        let budget = PollingBudget(duration: 5.0)
        budget.start()

        budget.invalidate()
        XCTAssertTrue(budget.hasPolledFinal)

        // Multiple invalidations should be safe
        budget.invalidate()
        XCTAssertTrue(budget.hasPolledFinal)
        XCTAssertFalse(budget.hasBudgetRemaining)
    }
}
