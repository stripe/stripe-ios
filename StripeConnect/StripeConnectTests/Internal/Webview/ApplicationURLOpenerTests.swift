//
//  ApplicationURLOpenerTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/8/24.
//

@testable import StripeConnect
import XCTest

class ApplicationURLOpenerTests: XCTestCase {
    func testCantOpenUrlThrowsError() throws {
        let mockURL = URL(string: "https://stripe.com?query=value")!

        // By default, MockURLOpener returns `false` for `canOpen`
        let urlOpener = MockURLOpener()
        do {
            try urlOpener.openIfPossible(mockURL)
            XCTFail("Expected error to be thrown")
        } catch let error as URLOpenError {
            XCTAssertEqual(error.url, mockURL)
            XCTAssertEqual(error.analyticLoggableSerializeForLogging() as NSDictionary, [
                "url": "https://stripe.com"
            ])
        }
    }
}
