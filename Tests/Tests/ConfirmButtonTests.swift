//
//  ConfirmButtonTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 10/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class ConfirmButtonTests: XCTestCase {

    func testBuyButtonShouldAutomaticallyAdjustItsForegroundColor() {
        let testCases: [(background: UIColor, foreground: UIColor)] = [
            // Dark backgrounds
            (background: .systemBlue, foreground: .white),
            (background: .black, foreground: .white),
            // Light backgrounds
            (background: UIColor(red: 1.0, green: 0.87, blue: 0.98, alpha: 1.0), foreground: .black),
            (background: UIColor(red: 1.0, green: 0.89, blue: 0.35, alpha: 1.0), foreground: .black)
        ]

        for (backgroundColor, expectedForeground) in testCases {
            let button = ConfirmButton.BuyButton()
            button.tintColor = backgroundColor
            button.update(status: .enabled, callToAction: .pay(amount: 900, currency: "usd"), animated: false)

            XCTAssertEqual(
                // Test against `.cgColor` because any color set as `.backgroundColor`
                // will be automatically wrapped in `UIDynamicModifiedColor` (private subclass) by iOS.
                button.backgroundColor?.cgColor,
                backgroundColor.cgColor
            )

            XCTAssertEqual(
                button.foregroundColor,
                expectedForeground,
                "The foreground color should contrast with the background color"
            )
        }
    }

    func testUpdateShouldCallTheCompletionBlock() {
        let sut = ConfirmButton(style: .stripe, callToAction: .pay(amount: 1000, currency: "usd"), didTap: {})

        let expectation = XCTestExpectation(description: "Should call the completion block")

        sut.update(state: .disabled, animated: false) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testUpdateShouldCallTheCompletionBlockWhenAnimated() {
        let sut = ConfirmButton(style: .stripe, callToAction: .pay(amount: 1000, currency: "usd"), didTap: {})

        let expectation = XCTestExpectation(description: "Should call the completion block")

        sut.update(state: .disabled, animated: true) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

}
