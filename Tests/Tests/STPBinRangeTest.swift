//
//  STPBinRangeTest.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPBinRangeTest: XCTestCase {
    func testAllRanges() {
        for binRange in STPBINController.shared.allRanges() {
            XCTAssertEqual(binRange.accountRangeLow.count, binRange.accountRangeHigh.count)
        }
    }

    func testMatchesNumber() {
        var binRange = STPBINRange(
            panLength: 0, brand: .unknown, accountRangeLow: "134", accountRangeHigh: "167", country: nil)

        XCTAssertFalse(binRange.matchesNumber("0"))
        XCTAssertTrue(binRange.matchesNumber("1"))
        XCTAssertFalse(binRange.matchesNumber("2"))

        XCTAssertFalse(binRange.matchesNumber("00"))
        XCTAssertTrue(binRange.matchesNumber("13"))
        XCTAssertTrue(binRange.matchesNumber("14"))
        XCTAssertTrue(binRange.matchesNumber("16"))
        XCTAssertFalse(binRange.matchesNumber("20"))

        XCTAssertFalse(binRange.matchesNumber("133"))
        XCTAssertTrue(binRange.matchesNumber("134"))
        XCTAssertTrue(binRange.matchesNumber("135"))
        XCTAssertTrue(binRange.matchesNumber("167"))
        XCTAssertFalse(binRange.matchesNumber("168"))

        XCTAssertFalse(binRange.matchesNumber("1244"))
        XCTAssertTrue(binRange.matchesNumber("1340"))
        XCTAssertTrue(binRange.matchesNumber("1344"))
        XCTAssertTrue(binRange.matchesNumber("1444"))
        XCTAssertTrue(binRange.matchesNumber("1670"))
        XCTAssertTrue(binRange.matchesNumber("1679"))
        XCTAssertFalse(binRange.matchesNumber("1680"))

        binRange = STPBINRange(
            panLength: 0, brand: .unknown, accountRangeLow: "004", accountRangeHigh: "017", country: nil)

        XCTAssertTrue(binRange.matchesNumber("0"))
        XCTAssertFalse(binRange.matchesNumber("1"))

        XCTAssertTrue(binRange.matchesNumber("00"))
        XCTAssertTrue(binRange.matchesNumber("01"))
        XCTAssertFalse(binRange.matchesNumber("10"))
        XCTAssertFalse(binRange.matchesNumber("20"))

        XCTAssertFalse(binRange.matchesNumber("000"))
        XCTAssertFalse(binRange.matchesNumber("002"))
        XCTAssertTrue(binRange.matchesNumber("004"))
        XCTAssertTrue(binRange.matchesNumber("009"))
        XCTAssertTrue(binRange.matchesNumber("014"))
        XCTAssertTrue(binRange.matchesNumber("017"))
        XCTAssertFalse(binRange.matchesNumber("019"))
        XCTAssertFalse(binRange.matchesNumber("020"))
        XCTAssertFalse(binRange.matchesNumber("100"))

        XCTAssertFalse(binRange.matchesNumber("0000"))
        XCTAssertFalse(binRange.matchesNumber("0021"))
        XCTAssertTrue(binRange.matchesNumber("0044"))
        XCTAssertTrue(binRange.matchesNumber("0098"))
        XCTAssertTrue(binRange.matchesNumber("0143"))
        XCTAssertTrue(binRange.matchesNumber("0173"))
        XCTAssertFalse(binRange.matchesNumber("0195"))
        XCTAssertFalse(binRange.matchesNumber("0202"))
        XCTAssertFalse(binRange.matchesNumber("1004"))

        binRange = STPBINRange(
            panLength: 0, brand: .unknown, accountRangeLow: "", accountRangeHigh: "", country: nil)
        XCTAssertTrue(binRange.matchesNumber(""))
        XCTAssertTrue(binRange.matchesNumber("1"))
    }

    func testBinRangesForNumber() {
        var binRanges: [STPBINRange]?

        binRanges = STPBINController.shared.binRanges(forNumber: "4136000000008")
        XCTAssertEqual(binRanges?.count, 3)

        binRanges = STPBINController.shared.binRanges(forNumber: "4242424242424242")
        XCTAssertEqual(binRanges?.count, 2)

        binRanges = STPBINController.shared.binRanges(forNumber: "5555555555554444")
        XCTAssertEqual(binRanges?.count, 2)

        binRanges = STPBINController.shared.binRanges(forNumber: "")
        XCTAssertEqual(binRanges?.count, STPBINController.shared.allRanges().count)

        binRanges = STPBINController.shared.binRanges(forNumber: "123")
        XCTAssertEqual(binRanges?.count, 1)
    }

    func testBinRangesForBrand() {
        let allBrands: [STPCardBrand] = [
            .visa,
            .amex,
            .mastercard,
            .discover,
            .JCB,
            .dinersClub,
            .unionPay,
            .unknown,
        ]
        for brand in allBrands {
            let binRanges = STPBINController.shared.binRanges(for: brand)
            for binRange in binRanges {
                XCTAssertEqual(binRange.brand, brand)
            }
        }
    }

    func testMostSpecificBinRangeForNumber() {
        var binRange: STPBINRange?

        binRange = STPBINController.shared.mostSpecificBINRange(forNumber: "")
        XCTAssertNotEqual(binRange?.brand, .unknown)

        binRange = STPBINController.shared.mostSpecificBINRange(forNumber: "4242424242422")
        XCTAssertEqual(binRange?.brand, .visa)
        XCTAssertEqual(binRange?.panLength, 16)

        binRange = STPBINController.shared.mostSpecificBINRange(forNumber: "4136000000008")
        XCTAssertEqual(binRange?.brand, .visa)
        XCTAssertEqual(binRange?.panLength, 13)

        binRange = STPBINController.shared.mostSpecificBINRange(forNumber: "4242424242424242")
        XCTAssertEqual(binRange?.brand, .visa)
        XCTAssertEqual(binRange?.panLength, 16)
    }
}
