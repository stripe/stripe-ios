//
//  URL+ExtensionTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/8/24.
//

@testable import StripeConnect
import XCTest

class URL_ExtensionTests: XCTestCase {
    func testAbsoluteStringRemovingParams() {
        verify(url: "https://stripe.com?query=value", removingParamsIs: "https://stripe.com")
        verify(url: "https://stripe.com#hashquery=value", removingParamsIs: "https://stripe.com")
        verify(url: "https://stripe.com#hashquery=value?query=value", removingParamsIs: "https://stripe.com")
        verify(url: "https://stripe.com/somepath/file.html#hashquery=value?query=value", removingParamsIs: "https://stripe.com/somepath/file.html")
    }
}

private extension URL_ExtensionTests {
    func verify(url: String,
                removingParamsIs expectedResult: String,
                line: UInt = #line) {
        XCTAssertEqual(URL(string: url)!.absoluteStringRemovingParams, expectedResult, line: line)
    }
}
