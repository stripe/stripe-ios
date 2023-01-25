//
//  StringExtensionsTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Krisjanis Gaidis on 7/14/22.
//

@testable import StripeFinancialConnections
import XCTest

class StringExtensionsTests: XCTestCase {

    func testExtractingLinksFromString() throws {
        XCTAssert("Not Equal Test".extractLinks() != ("Wrong Word", []))
        XCTAssert("No Link".extractLinks() == ("No Link", []))
        XCTAssert(
            "[One Link](https://www.stripe.com/terms)".extractLinks()
                == (
                    "One Link",
                    [String.Link(range: NSRange(location: 0, length: 8), urlString: "https://www.stripe.com/terms")]
                )
        )
        XCTAssert(
            "[Complex Link](https://stripe.com/docs/api/financial_connections/ownership/object#financial_connections_ownership_object-id)"
                .extractLinks()
                == (
                    "Complex Link",
                    [
                        String.Link(
                            range: NSRange(location: 0, length: 12),
                            urlString:
                                "https://stripe.com/docs/api/financial_connections/ownership/object#financial_connections_ownership_object-id"
                        ),
                    ]
                )
        )
        XCTAssert(
            "Word [Link 1](https://www.stripe.com/link1) word [Link 2](https://www.stripe.com/link2) word"
                .extractLinks()
                == (
                    "Word Link 1 word Link 2 word",
                    [
                        String.Link(range: NSRange(location: 5, length: 6), urlString: "https://www.stripe.com/link1"),
                        String.Link(range: NSRange(location: 17, length: 6), urlString: "https://www.stripe.com/link2"),
                    ]
                )
        )
    }
}
