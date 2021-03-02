//
//  STPCardBINMetadata.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPCardBINMetadataTests: XCTestCase {
    func testAPICall() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey

        let expectation = self.expectation(description: "Retrieve card metadata")

        // 625035 is a randomly selected UnionPay BIN
        STPAPIClient.shared.retrieveCardBINMetadata(
            forPrefix: "625035",
            withCompletion: { cardMetadata, error in
                XCTAssertNotNil(cardMetadata)
                XCTAssertTrue((cardMetadata?.ranges.count ?? 0) > 0)
                XCTAssertNil(error)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLoadingInBINRange() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey

        let expectation = self.expectation(description: "Retrieve card metadata")
        let hardCodedBinRanges = STPBINRange.allRanges()
        STPBINRange.retrieveBINRanges(forPrefix: "625035") { ranges, error in
            XCTAssertNotNil(ranges)
            XCTAssertNil(error)
            XCTAssertTrue((ranges?.count ?? 0) > 0)
            XCTAssertTrue(
                STPBINRange.allRanges().count == hardCodedBinRanges.count + (ranges?.count ?? 0))
            for range in ranges ?? [] {
                XCTAssertTrue(STPBINRange.allRanges().contains(range))
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)

    }
}
