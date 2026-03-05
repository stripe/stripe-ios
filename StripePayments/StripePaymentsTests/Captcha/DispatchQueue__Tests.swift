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
