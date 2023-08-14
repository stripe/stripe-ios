//
//  XCUIElement+Extensions.swift
//  FinancialConnectionsUITests
//
//  Created by Krisjanis Gaidis on 8/14/23.
//

import Foundation
import XCTest

extension XCUIElement {

    fileprivate func wait(
        until expression: @escaping (XCUIElement) -> Bool,
        timeout: TimeInterval
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                expression(self)
            },
            object: nil
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return (result == .completed)
    }

    func turnSwitch(on: Bool) {
        if (value as? String) == (on ? "0" : "1") {
            tap()
            // starting iOS 16.4 (where 16.1 previously worked), calling
            // `tap()` on a switch didn't do anything, so below we
            // try a different method...
            if (value as? String) == (on ? "0" : "1") {
                let coordinate = coordinate(
                    withNormalizedOffset: CGVector(
                        dx: 0.9,
                        dy: 0.5
                    )
                )
                coordinate.tap()
            }
        }
        XCTAssert(wait(
            until: { ($0.value as? String == (on ? "1" : "0")) },
            timeout: 5
        ), "switch failed to change")
    }
}
