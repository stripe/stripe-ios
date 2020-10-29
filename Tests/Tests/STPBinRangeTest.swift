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
    for binRange in STPBINRange.allRanges() {
      XCTAssertEqual(binRange.qRangeLow.count, binRange.qRangeHigh.count)
    }
  }

  func testMatchesNumber() {
    var binRange = STPBINRange(length: 0, brand: .unknown, qRangeLow: "134", qRangeHigh: "167", country: nil, isCardMetadata: false)

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

    binRange = STPBINRange(length: 0, brand: .unknown, qRangeLow: "004", qRangeHigh: "017", country: nil, isCardMetadata: false)

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

    binRange = STPBINRange(length: 0, brand: .unknown, qRangeLow: "", qRangeHigh: "", country: nil, isCardMetadata: false)
    XCTAssertTrue(binRange.matchesNumber(""))
    XCTAssertTrue(binRange.matchesNumber("1"))
  }

  func testBinRangesForNumber() {
    var binRanges: [STPBINRange]?

    binRanges = STPBINRange.binRanges(forNumber: "4136000000008")
    XCTAssertEqual(binRanges?.count, 3)

    binRanges = STPBINRange.binRanges(forNumber: "4242424242424242")
    XCTAssertEqual(binRanges?.count, 2)

    binRanges = STPBINRange.binRanges(forNumber: "5555555555554444")
    XCTAssertEqual(binRanges?.count, 2)

    binRanges = STPBINRange.binRanges(forNumber: "")
    XCTAssertEqual(binRanges?.count, STPBINRange.allRanges().count)

    binRanges = STPBINRange.binRanges(forNumber: "123")
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
      let binRanges = STPBINRange.binRanges(for: brand)
      for binRange in binRanges {
        XCTAssertEqual(binRange.brand, brand)
      }
    }
  }

  func testMostSpecificBinRangeForNumber() {
    var binRange: STPBINRange?

    binRange = STPBINRange.mostSpecificBINRange(forNumber: "")
    XCTAssertNotEqual(binRange?.brand, .unknown)

    binRange = STPBINRange.mostSpecificBINRange(forNumber: "4242424242422")
    XCTAssertEqual(binRange?.brand, .visa)
    XCTAssertEqual(binRange?.length, 16)

    binRange = STPBINRange.mostSpecificBINRange(forNumber: "4136000000008")
    XCTAssertEqual(binRange?.brand, .visa)
    XCTAssertEqual(binRange?.length, 13)

    binRange = STPBINRange.mostSpecificBINRange(forNumber: "4242424242424242")
    XCTAssertEqual(binRange?.brand, .visa)
    XCTAssertEqual(binRange?.length, 16)
  }
}
