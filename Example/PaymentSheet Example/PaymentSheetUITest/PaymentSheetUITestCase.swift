//
//  PaymentSheetUITestCase.swift
//  PaymentSheetUITest
//
//  Created by David Estes on 1/21/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import XCTest

class PaymentSheetUITestCase: XCTestCase {
    var app: XCUIApplication!

    /// This element's `label` contains all the analytic events sent by the SDK since the the playground was loaded, as a base-64 encoded string.
    /// - Note: Only exists in test playground.
    lazy var analyticsLogElement: XCUIElement = { app.staticTexts["_testAnalyticsLog"] }()
    /// Convenience var to grab all the events sent since the playground was loaded.
    var analyticsLog: [[String: Any]] {
        let logRawString = analyticsLogElement.label
        guard
            let data = Data(base64Encoded: logRawString),
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return []
        }
        return json
    }

    /// JSON of the checkout session billing address (playground / Checkout Session only).
    lazy var checkoutBillingAddressElement: XCUIElement = { app.staticTexts["_testCheckoutBillingAddress"] }()

    var checkoutBillingAddress: [String: Any] {
        guard
            let data = checkoutBillingAddressElement.label.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return json
    }

    func waitForCheckoutBillingAddress(
        country: String? = nil,
        postalCode: String? = nil,
        line1: String? = nil,
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            checkoutBillingAddressElement.waitForExistence(timeout: timeout),
            "Checkout billing address debug element never appeared",
            file: file,
            line: line
        )

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let address = checkoutBillingAddress
            let countryMatches = country == nil || address["country"] as? String == country
            let postalMatches = postalCode == nil || address["postalCode"] as? String == postalCode
            let line1Matches = line1 == nil || address["line1"] as? String == line1
            if address["country"] != nil, countryMatches, postalMatches, line1Matches {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTFail(
            "Timed out waiting for checkout billing address. Last value: \(checkoutBillingAddress)",
            file: file,
            line: line
        )
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = [
            "UITesting": "true",
            // This makes the Financial Connections SDK trigger the (testmode) production flow instead of a stub. See `FinancialConnectionsSDKAvailability`.
            "FinancialConnectionsSDKAvailable": "true",
            "FinancialConnectionsStubbedResult": "false",
        ]
    }
}

// XCTest runs classes in parallel, not individual tests. Split the tests into separate classes to keep build times at a reasonable level.
