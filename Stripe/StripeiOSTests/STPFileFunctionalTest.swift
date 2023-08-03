//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPFileFunctionalTest.swift
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import XCTest

class STPFileFunctionalTest: XCTestCase {
    func testImage() -> UIImage? {
        return UIImage(
            named: "stp_test_upload_image.jpeg",
            in: Bundle(for: STPFileFunctionalTest.self),
            compatibleWith: nil)
    }

    func testCreateFileForIdentityDocument() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "File creation for identity document")

        let image = testImage()

        client.uploadImage(
            image,
            purpose: STPFilePurposeIdentityDocument) { file, error in
            expectation.fulfill()
            XCTAssertNil(error)

            XCTAssertNotNil(file?.fileId ?? 0)
            XCTAssertNotNil(file?.created ?? 0)
            XCTAssertEqual(file?.purpose ?? 0, Int(STPFilePurposeIdentityDocument))
            XCTAssertNotNil(file?.size ?? 0)
            XCTAssertEqual("jpg", file?.type)
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateFileForDisputeEvidence() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "File creation for dispute evidence")

        let image = testImage()

        client.uploadImage(
            image,
            purpose: STPFilePurposeDisputeEvidence) { file, error in
            expectation.fulfill()
            XCTAssertNil(error)

            XCTAssertNotNil(file?.fileId ?? 0)
            XCTAssertNotNil(file?.created ?? 0)
            XCTAssertEqual(file?.purpose ?? 0, Int(STPFilePurposeDisputeEvidence))
            XCTAssertNotNil(file?.size ?? 0)
            XCTAssertEqual("jpg", file?.type)
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testInvalidKey() {
        let client = STPAPIClient(publishableKey: "not_a_valid_key_asdf")

        let expectation = self.expectation(description: "Bad file creation")

        let image = testImage()

        client.uploadImage(
            image,
            purpose: STPFilePurposeIdentityDocument) { file, error in
            expectation.fulfill()
            XCTAssertNil(Int(file ?? 0))
            XCTAssertNotNil(error)
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }
}
