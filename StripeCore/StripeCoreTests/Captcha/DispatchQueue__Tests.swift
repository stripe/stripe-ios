//
//  DispatchQueue__Tests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 21/12/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import StripePayments
import XCTest

class DispatchQueue__Tests: XCTestCase {

    // MARK: Throttle

    func test__Throttle_Nil_Context() {
        // Execute closure called once
        let exp0 = expectation(description: "did call single closure")

        DispatchQueue.main.throttle(deadline: .now() + 0.01) {
            exp0.fulfill()
        }

        waitForExpectations(timeout: 1)

        // Does not execute first closure
        let exp1 = expectation(description: "did call last closure")
        DispatchQueue.main.throttle(deadline: .now() + 0.01) {
            XCTFail("Shouldn't be called")
        }

        DispatchQueue.main.throttle(
            deadline: .now() + 0.01,
            action: exp1.fulfill
        )

        waitForExpectations(timeout: 1)
    }

    func test__Throttle_Context() {
        // Execute closure called once
        let exp0 = expectation(description: "did call single closure")
        let c0 = UUID()

        DispatchQueue.main.throttle(
            deadline: .now() + 0.01,
            context: c0,
            action: exp0.fulfill
        )

        waitForExpectations(timeout: 1)

        // Does not execute first closure
        let exp1 = expectation(description: "execute on valid context")
        let c1 = UUID()
        DispatchQueue.main.throttle(deadline: .now() + 0.01, context: c1) {
            XCTFail("Shouldn't be called")
        }

        DispatchQueue.main.throttle(
            deadline: .now() + 0.01,
            context: c1,
            action: exp1.fulfill
        )

        // Execute in a different context
        let exp2 = expectation(description: "execute on different context")
        let c2 = UUID()
        DispatchQueue.main.throttle(
            deadline: .now() + 0.01,
            context: c2,
            action: exp2.fulfill
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: Debounce

    func test__Debounce_Nil_Context() {
        // Does not execute sequenced closures
        let exp0 = expectation(description: "did call first closure")

        DispatchQueue.main.debounce(
            interval: 0.01,
            action: exp0.fulfill
        )

        DispatchQueue.main.debounce(interval: 0) {
            XCTFail("Shouldn't be called")
        }

        waitForExpectations(timeout: 1)

        // Executes closure after previous has timed out
        let exp1 = expectation(description: "did call closure")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            DispatchQueue.main.debounce(
                interval: 0.01,
                action: exp1.fulfill
            )
        }

        waitForExpectations(timeout: 3)
    }

    func test__Debounce_Context() {
        // Does not execute sequenced closures
        let exp0 = expectation(description: "did call first closure")
        let c0 = UUID()

        DispatchQueue.main.debounce(
            interval: 0.01,
            context: c0,
            action: exp0.fulfill
        )

        DispatchQueue.main.debounce(interval: 0, context: c0) {
            XCTFail("Shouldn't be called")
        }

        // Execute in a different context
        let c1 = UUID()
        let exp1 = expectation(description: "executes in different context")
        DispatchQueue.main.debounce(
            interval: 0,
            context: c1,
            action: exp1.fulfill
        )

        waitForExpectations(timeout: 1)

        // Executes closure after previous has timed out
        let exp2 = expectation(description: "did call closure")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            DispatchQueue.main.debounce(
                interval: 0.01,
                context: c0,
                action: exp2.fulfill
            )
        }

        waitForExpectations(timeout: 5)
    }

    // MARK: Once

    func test__Once__Single_Dispatch() {
        let token = 3
        var dispatchCount = 0

        // Does dispatch the given action
        DispatchQueue.once(token: token) {
            dispatchCount = 1
        }

        XCTAssertEqual(dispatchCount, 1)

        // Does not dispatch again for the same token
        DispatchQueue.once(token: token) {
            dispatchCount = 2
        }

        XCTAssertEqual(dispatchCount, 1)
    }

    func test__Once__Multiple_Dispatches() {
        let token1 = 4
        var didDispatch1 = false

        // Does dispatch the given action
        DispatchQueue.once(token: token1) {
            didDispatch1 = true
        }

        XCTAssertTrue(didDispatch1)

        // Dispatch for a different token
        let token2 = 6
        var didDispatch2 = false

        DispatchQueue.once(token: token2) {
            didDispatch2 = true
        }

        XCTAssertTrue(didDispatch2)
    }
}
