//
//  FCLiteImplementationTests.swift
//  StripeFinancialConnectionsLiteTests
//
//  Created by Mat Schmid on 6/20/25.
//

@_spi(STP) import StripeCore
import XCTest

class FCLiteImplementationTests: XCTestCase {
    func testFCLiteImplementationAvailable() {
        let FinancialConnectionsLiteImplementation: FinancialConnectionsSDKInterface.Type? =
            NSClassFromString("StripeFinancialConnectionsLite.FCLiteImplementation")
            as? FinancialConnectionsSDKInterface.Type
        XCTAssertNotNil(FinancialConnectionsLiteImplementation)
    }
}
