//
//  STPCardBINMetadataTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPCardBINMetadataTests: XCTestCase {
    func testAPICall() {
        let expectation = self.expectation(description: "Retrieve card metadata")

        // 625035 is a randomly selected UnionPay BIN
        STPBINRange.retrieve(
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            forPrefix: "625035",
            completion: { result in
                let cardMetadata = try! result.get()
                XCTAssertTrue(cardMetadata.data.count > 0)
                XCTAssertEqual(cardMetadata.data.first!.brand, .unionPay)
                expectation.fulfill()
            }
        )
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLoadingInBINRange() {
        let expectation = self.expectation(description: "Retrieve card metadata")
        let hardCodedBinRanges = STPBINController.shared.allRanges()
        STPBINController.shared.retrieveBINRanges(
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            forPrefix: "625035") { result in
            let ranges = try! result.get()
            XCTAssertTrue(ranges.count > 0)
            XCTAssertTrue(
                STPBINController.shared.allRanges().count == hardCodedBinRanges.count + ranges.count
            )
            for range in ranges {
                XCTAssertTrue(STPBINController.shared.allRanges().contains(range))
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)

    }
}
