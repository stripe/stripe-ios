//
//  AnalyticsHelperTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe
@_spi(STP) @testable import StripeCore

class AnalyticsHelperTests: XCTestCase {

    func test_getDuration() {
        let (sut, timeReference) = makeSUT()

        sut.startTimeMeasurement(.checkout)

        // Advance the clock by 10 seconds.
        timeReference.advanceBy(10)
        XCTAssertEqual(sut.getDuration(for: .checkout), 10)

        // Advance the clock by 5 seconds.
        timeReference.advanceBy(5)
        XCTAssertEqual(sut.getDuration(for: .checkout), 15)
    }

    func test_getDuration_returnsNilWhenNotStarted() {
        let (sut, _) = makeSUT()
        XCTAssertNil(sut.getDuration(for: .checkout))
    }

}

extension AnalyticsHelperTests {

    class MockTimeReference {
        var date = Date()

        func advanceBy(_ timeInterval: TimeInterval) {
            date = date.addingTimeInterval(timeInterval)
        }

        func now() -> Date {
            return date
        }
    }

    func makeSUT() -> (AnalyticsHelper, MockTimeReference) {
        let timeReference = MockTimeReference()
        let helper = AnalyticsHelper(timeProvider: timeReference.now)
        return (helper, timeReference)
    }

}
