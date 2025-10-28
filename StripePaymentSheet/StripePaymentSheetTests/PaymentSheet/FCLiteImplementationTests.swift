//
//  FCLiteImplementationTests.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 2025-03-28.
//

@_spi(STP) import StripeCore
import XCTest

class FCLiteImplementationTests: XCTestCase {
    func testFCLiteImplementationAvailable() {
        let FinancialConnectionsLiteImplementation: FinancialConnectionsSDKInterface.Type? =
            NSClassFromString("StripePaymentSheet.FCLiteImplementation")
            as? FinancialConnectionsSDKInterface.Type
        XCTAssertNotNil(FinancialConnectionsLiteImplementation)
    }
}
