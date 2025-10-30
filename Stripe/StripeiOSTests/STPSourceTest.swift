//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceTest.m
//  Stripe
//
//  Created by Ben Guo on 1/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import StripePayments
@testable import StripePaymentsUI
import XCTest

class STPSourceTest: XCTestCase {
    // MARK: - STPSourceType Tests

    func testTypeFromString() {

        XCTAssertEqual(STPSource.type(from: "card"), STPSourceType.card)
        XCTAssertEqual(STPSource.type(from: "CARD"), STPSourceType.card)

        XCTAssertEqual(STPSource.type(from: "unknown"), STPSourceType.unknown)
        XCTAssertEqual(STPSource.type(from: "UNKNOWN"), STPSourceType.unknown)

        XCTAssertEqual(STPSource.type(from: "garbage"), STPSourceType.unknown)
        XCTAssertEqual(STPSource.type(from: "GARBAGE"), STPSourceType.unknown)
    }

    func testStringFromType() {
        let values = [
            STPSourceType.card,
            STPSourceType.unknown,
        ]

        for type in values {
            let string = STPSource.string(from: type)

            switch type {
            case STPSourceType.card:
                XCTAssertEqual(string, "card")
            case STPSourceType.unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - STPSourceStatus Tests

    func testStatusFromString() {
        XCTAssertEqual(STPSource.status(from: "pending"), STPSourceStatus.pending)
        XCTAssertEqual(STPSource.status(from: "PENDING"), STPSourceStatus.pending)

        XCTAssertEqual(STPSource.status(from: "chargeable"), STPSourceStatus.chargeable)
        XCTAssertEqual(STPSource.status(from: "CHARGEABLE"), STPSourceStatus.chargeable)

        XCTAssertEqual(STPSource.status(from: "consumed"), STPSourceStatus.consumed)
        XCTAssertEqual(STPSource.status(from: "CONSUMED"), STPSourceStatus.consumed)

        XCTAssertEqual(STPSource.status(from: "canceled"), STPSourceStatus.canceled)
        XCTAssertEqual(STPSource.status(from: "CANCELED"), STPSourceStatus.canceled)

        XCTAssertEqual(STPSource.status(from: "failed"), STPSourceStatus.failed)
        XCTAssertEqual(STPSource.status(from: "FAILED"), STPSourceStatus.failed)

        XCTAssertEqual(STPSource.status(from: "garbage"), STPSourceStatus.unknown)
        XCTAssertEqual(STPSource.status(from: "GARBAGE"), STPSourceStatus.unknown)
    }

    func testStringFromStatus() {
        let values = [
            STPSourceStatus.pending,
            STPSourceStatus.chargeable,
            STPSourceStatus.consumed,
            STPSourceStatus.canceled,
            STPSourceStatus.failed,
            STPSourceStatus.unknown,
        ]

        for status in values {
            let string = STPSource.string(from: status)

            switch status {
            case STPSourceStatus.pending:
                XCTAssertEqual(string, "pending")
            case STPSourceStatus.chargeable:
                XCTAssertEqual(string, "chargeable")
            case STPSourceStatus.consumed:
                XCTAssertEqual(string, "consumed")
            case STPSourceStatus.canceled:
                XCTAssertEqual(string, "canceled")
            case STPSourceStatus.failed:
                XCTAssertEqual(string, "failed")
            case STPSourceStatus.unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - STPSourceUsage Tests

    func testUsageFromString() {
        XCTAssertEqual(STPSource.usage(from: "reusable"), STPSourceUsage.reusable)
        XCTAssertEqual(STPSource.usage(from: "REUSABLE"), STPSourceUsage.reusable)

        XCTAssertEqual(STPSource.usage(from: "single_use"), STPSourceUsage.singleUse)
        XCTAssertEqual(STPSource.usage(from: "SINGLE_USE"), STPSourceUsage.singleUse)

        XCTAssertEqual(STPSource.usage(from: "garbage"), STPSourceUsage.unknown)
        XCTAssertEqual(STPSource.usage(from: "GARBAGE"), STPSourceUsage.unknown)
    }

    func testStringFromUsage() {
        let values = [
            STPSourceUsage.reusable,
            STPSourceUsage.singleUse,
            STPSourceUsage.unknown,
        ]

        for usage in values {
            let string = STPSource.string(from: usage)

            switch usage {
            case STPSourceUsage.reusable:
                XCTAssertEqual(string, "reusable")
            case STPSourceUsage.singleUse:
                XCTAssertEqual(string, "single_use")
            case STPSourceUsage.unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - Equality Tests

    func testSourceEquals() {
        let source1 = STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("CardSource"))
        let source2 = STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("CardSource"))

        XCTAssertEqual(source1, source1)
        XCTAssertEqual(source1, source2)

        XCTAssertEqual(source1?.hash, source1?.hash)
        XCTAssertEqual(source1?.hash, source2?.hash)
    }

    // MARK: - Description Tests

    func testDescription() {
        let source = STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("CardSource"))
        XCTAssertNotNil(source?.description)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "id",
            "livemode",
            "status",
            "type",
        ]

        for field in requiredFields {
            var response = STPTestUtils.jsonNamed("CardSource")
            response?.removeValue(forKey: field)

            XCTAssertNil(STPSource.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("CardSource")))
    }

    func testDecodingSource_3ds() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSource3DS)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_456")
        XCTAssertEqual(source?.amount, NSNumber(value: 1099))
        XCTAssertEqual(source?.clientSecret, "src_client_secret_456")
        XCTAssertEqual(source?.created?.timeIntervalSince1970 ?? 0, 1483663790.0, accuracy: 1.0)
        XCTAssertEqual(source?.currency, "eur")
        XCTAssertEqual(source?.livemode, false)
        XCTAssertNil(source?.perform(NSSelectorFromString("metadata")))
        XCTAssertEqual(source?.status, STPSourceStatus.pending)
        XCTAssertEqual(source?.usage, STPSourceUsage.singleUse)
        var threedsecure = response?["three_d_secure"] as? [AnyHashable: Any]
        threedsecure?.removeValue(forKey: "customer") // should be nil
//        XCTAssertEqual(source?.details, threedsecure)
        XCTAssertNotNil(source?.details)
        XCTAssertNil(source?.cardDetails) // STPSourceCardDetailsTest
    }

    func testDecodingSource_card() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSourceCard)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_123")
        XCTAssertNil(source?.amount)
        XCTAssertEqual(source?.clientSecret, "src_client_secret_123")
        XCTAssertEqual(source?.created?.timeIntervalSince1970 ?? 0, 1483575790.0, accuracy: 1.0)
        XCTAssertNil(source?.currency)
        XCTAssertEqual(source?.livemode, false)
        XCTAssertNil(source?.perform(NSSelectorFromString("metadata")))
        XCTAssertEqual(source?.status, STPSourceStatus.chargeable)
        XCTAssertEqual(source?.type, STPSourceType.card)
        XCTAssertEqual(source?.usage, STPSourceUsage.reusable)
        XCTAssertEqual(source!.details! as NSDictionary, response!["card"] as! NSDictionary)
        XCTAssertNotNil(source?.cardDetails) // STPSourceCardDetailsTest
    }

    func possibleAPIResponses() -> [[AnyHashable: Any]] {
        return [
            STPTestUtils.jsonNamed(STPTestJSONSourceCard),
            STPTestUtils.jsonNamed(STPTestJSONSource3DS),
        ]
    }

}
