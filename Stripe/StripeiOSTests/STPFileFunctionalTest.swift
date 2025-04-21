//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPFileFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

class STPFileFunctionalTest: STPNetworkStubbingTestCase {
    func testImage() -> UIImage {
        return UIImage(
            named: "stp_test_upload_image.jpeg",
            in: Bundle(for: STPFileFunctionalTest.self),
            compatibleWith: nil)!
    }

    func testCreateFileForIdentityDocument() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "File creation for identity document")

        let image = testImage()

        client.uploadImage(
            image,
            purpose: .identityDocument) { file, error in
            expectation.fulfill()
            XCTAssertNil(error, "error should be nil")

            XCTAssertNotNil(file?.fileId)
            XCTAssertNotNil(file?.created)
                XCTAssertEqual(file?.purpose, .identityDocument)
            XCTAssertNotNil(file?.size)
            XCTAssertEqual("jpg", file?.type)
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateFileForDisputeEvidence() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "File creation for dispute evidence")

        let image = testImage()

        client.uploadImage(
            image,
            purpose: .disputeEvidence) { file, error in
            expectation.fulfill()
            XCTAssertNil(error, "error should be nil")

            XCTAssertNotNil(file?.fileId)
            XCTAssertNotNil(file?.created)
                XCTAssertEqual(file?.purpose, .disputeEvidence)
            XCTAssertNotNil(file?.size)
            XCTAssertEqual("jpg", file?.type)
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testInvalidKey() {
        let client = STPAPIClient(publishableKey: "not_a_valid_key_asdf")

        let expectation = self.expectation(description: "Bad file creation")

        let image = testImage()

        client.uploadImage(
            image,
            purpose: .identityDocument) { file, error in
            expectation.fulfill()
            XCTAssertNil(file, "file should be nil")
            XCTAssertNotNil(error, "error should not be nil")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
