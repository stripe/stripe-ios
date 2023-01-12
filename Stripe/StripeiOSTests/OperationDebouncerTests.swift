//
//  OperationDebouncerTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 1/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class OperationDebouncerTests: XCTestCase {

    func testEnqueueShouldDebounce() {
        let sut = makeSUT()

        let expectation = self.expectation(description: "Should execute the block just once")
        expectation.assertForOverFulfill = true

        // Call `enqueue(block:)` 3 times
        for _ in 0..<3 {
            sut.enqueue {
                expectation.fulfill()
            }
        }

        Thread.sleep(forTimeInterval: 1)

        wait(for: [expectation], timeout: 1)
    }

}

extension OperationDebouncerTests {

    func makeSUT() -> OperationDebouncer {
        return OperationDebouncer(debounceTime: .milliseconds(500))
    }

}
