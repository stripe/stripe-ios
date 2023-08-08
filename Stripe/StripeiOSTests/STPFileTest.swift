//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPFileTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import StripePayments
import XCTest

class STPFileTest: XCTestCase {
    // MARK: - STPFilePurpose Tests

    func testPurposeFromString() {
        XCTAssertEqual(STPFile.purpose(from: "dispute_evidence"), .disputeEvidence)
        XCTAssertEqual(STPFile.purpose(from: "DISPUTE_EVIDENCE"), .disputeEvidence)

        XCTAssertEqual(STPFile.purpose(from: "identity_document"), .identityDocument)
        XCTAssertEqual(STPFile.purpose(from: "IDENTITY_DOCUMENT"), .identityDocument)

        XCTAssertEqual(STPFile.purpose(from: "unknown"), .unknown)
        XCTAssertEqual(STPFile.purpose(from: "UNKNOWN"), .unknown)

        XCTAssertEqual(STPFile.purpose(from: "garbage"), .unknown)
        XCTAssertEqual(STPFile.purpose(from: "GARBAGE"), .unknown)
    }

    func testStringFromPurpose() {
        let values: [STPFilePurpose] = [
            .disputeEvidence,
            .identityDocument,
            .unknown,
        ]

        for purpose in values {
            let string = STPFile.string(from: purpose)

            switch purpose {
            case .disputeEvidence:
                XCTAssertEqual(string, "dispute_evidence")
            case .identityDocument:
                XCTAssertEqual(string, "identity_document")
            case .unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - Equality Tests

    func testFileEquals() {
        let file1 = STPFile.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("FileUpload"))
        let file2 = STPFile.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("FileUpload"))

        XCTAssertEqual(file1, file1)
        XCTAssertEqual(file1, file2)

        XCTAssertEqual(file1?.hash, file1?.hash)
        XCTAssertEqual(file1?.hash, file2?.hash)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "id",
            "created",
            "size",
            "purpose",
            "type",
        ]

        for field in requiredFields {
            var response = STPTestUtils.jsonNamed("FileUpload")
            response!.removeValue(forKey: field)

            XCTAssertNil(STPFile.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPFile.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("FileUpload")))
    }

    func testInitializingFileWithAttributeDictionary() {
        let response = STPTestUtils.jsonNamed("FileUpload")!
        let file = STPFile.decodedObject(fromAPIResponse: response)!

        XCTAssertEqual(file.fileId, "file_1AZl0o2eZvKYlo2CoIkwLzfd")
        XCTAssertEqual(file.created, Date(timeIntervalSince1970: 1498674938))
        XCTAssertEqual(file.purpose, .disputeEvidence)
        XCTAssertEqual(file.size, NSNumber(value: 34478))
        XCTAssertEqual(file.type, "jpg")

        XCTAssertEqual(file.allResponseFields as NSDictionary, response as NSDictionary)
    }
}
