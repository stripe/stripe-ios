//
//  StringExtensionsTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Krisjanis Gaidis on 7/14/22.
//

@_spi(STP) @testable import StripeCore
@testable import StripeFinancialConnections
import XCTest

class StringExtensionsTests: XCTestCase {

    private let nonBreakingSpace = "\u{00a0}"

    func testExtractingLinksFromString() throws {
        XCTAssert("Not Equal Test".extractLinks() != ("Wrong Word", []))
        XCTAssert("No Link".extractLinks() == ("No Link", []))
        XCTAssert(
            "[One Link](https://www.stripe.com/terms)".extractLinks()
                == (
                    "One\(nonBreakingSpace)Link",
                    [String.Link(range: NSRange(location: 0, length: 8), urlString: "https://www.stripe.com/terms")]
                )
        )
        XCTAssert(
            "[Complex Link](https://stripe.com/docs/api/financial_connections/ownership/object#financial_connections_ownership_object-id)"
                .extractLinks()
                == (
                    "Complex\(nonBreakingSpace)Link",
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
                    "Word Link\(nonBreakingSpace)1 word Link\(nonBreakingSpace)2 word",
                    [
                        String.Link(range: NSRange(location: 5, length: 6), urlString: "https://www.stripe.com/link1"),
                        String.Link(range: NSRange(location: 17, length: 6), urlString: "https://www.stripe.com/link2"),
                    ]
                )
        )
    }

    func testBrandedLocalizedStrings_useProvidedBrandDisplayName() {
        XCTAssertEqual(String.Localized.continue_with_link(brand: .link), "Continue with Link")
        XCTAssertEqual(String.Localized.continue_with_link(brand: .onelink), "Continue with Onelink")
        XCTAssertEqual(
            String.Localized.use_information_you_previously_saved_with_your_brand_account(brand: .onelink),
            "Use information you previously saved with your Onelink account."
        )
        XCTAssertEqual(
            String.Localized.your_account_was_connected_but_could_not_be_saved_to_brand(brand: .onelink),
            "Your account was connected, but couldn't be saved to Onelink."
        )
    }
}
