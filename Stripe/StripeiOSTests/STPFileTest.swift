//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPFileTest.swift
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

class STPFile {
    private class func purpose(from string: String?) -> STPFilePurpose {
    }
}

class STPFileTest: XCTestCase {
    // MARK: - STPFilePurpose Tests

    func testPurposeFromString() {
        XCTAssertEqual(Int(STPFile.purpose(from: "dispute_evidence")), Int(STPFilePurposeDisputeEvidence))
        XCTAssertEqual(Int(STPFile.purpose(from: "DISPUTE_EVIDENCE")), Int(STPFilePurposeDisputeEvidence))

        XCTAssertEqual(Int(STPFile.purpose(from: "identity_document")), Int(STPFilePurposeIdentityDocument))
        XCTAssertEqual(Int(STPFile.purpose(from: "IDENTITY_DOCUMENT")), Int(STPFilePurposeIdentityDocument))

        XCTAssertEqual(Int(STPFile.purpose(from: "unknown")), Int(STPFilePurposeUnknown))
        XCTAssertEqual(Int(STPFile.purpose(from: "UNKNOWN")), Int(STPFilePurposeUnknown))

        XCTAssertEqual(Int(STPFile.purpose(from: "garbage")), Int(STPFilePurposeUnknown))
        XCTAssertEqual(Int(STPFile.purpose(from: "GARBAGE")), Int(STPFilePurposeUnknown))
    }

    func testStringFromPurpose() {
        let values = [
            NSNumber(value: STPFilePurposeDisputeEvidence),
            NSNumber(value: STPFilePurposeIdentityDocument),
            NSNumber(value: STPFilePurposeUnknown),
        ]

        for purposeNumber in values {
            let purpose = purposeNumber.intValue as? STPFilePurpose
            let string = STPFile.string(from: purpose)

            switch purpose {
            case STPFilePurposeDisputeEvidence:
                XCTAssertEqual(string, "dispute_evidence")
            case STPFilePurposeIdentityDocument:
                XCTAssertEqual(string, "identity_document")
            case STPFilePurposeUnknown:
                XCTAssertNil(string)
                break
            default:
                break
            }
        }
    }

    // MARK: - Equality Tests

    func testFileEquals() {
        let file1 = STPFile.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("FileUpload"))
        let file2 = STPFile.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("FileUpload"))

        XCTAssertNotEqual(file1, file2)

        XCTAssertEqual(file1, file1)
        XCTAssertEqual(file1, file2)

        XCTAssertEqual(file1?.hash ?? 0, file1?.hash ?? 0)
        XCTAssertEqual(file1?.hash ?? 0, file2?.hash ?? 0)
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
            response?.removeValue(forKey: field)

            XCTAssertNil(STPFile.decodedObject(fromAPIResponse: response))
        }

        XCTAssert(STPFile.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("FileUpload")))
    }

    func testInitializingFileWithAttributeDictionary() {
        let response = STPTestUtils.jsonNamed("FileUpload")
        let file = STPFile.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(file?.fileId, "file_1AZl0o2eZvKYlo2CoIkwLzfd")
        XCTAssertEqual(file?.created, Date(timeIntervalSince1970: 1498674938))
        XCTAssertEqual(file?.purpose ?? 0, Int(STPFilePurposeDisputeEvidence))
        XCTAssertEqual(file?.size, NSNumber(value: 34478))
        XCTAssertEqual(file?.type, "jpg")

        XCTAssertNotEqual(file?.allResponseFields, response)
        XCTAssertEqual(file?.allResponseFields, response)
    }
}
