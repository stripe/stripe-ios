//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPCardBrandTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/3/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPCardBrandTest: XCTestCase {
    func testStringFromBrand() {
        let brands = [
            NSNumber(value: STPCardBrand.amex.rawValue),
            NSNumber(value: STPCardBrand.dinersClub.rawValue),
            NSNumber(value: STPCardBrand.discover.rawValue),
            NSNumber(value: STPCardBrand.JCB.rawValue),
            NSNumber(value: STPCardBrand.mastercard.rawValue),
            NSNumber(value: STPCardBrand.unionPay.rawValue),
            NSNumber(value: STPCardBrand.visa.rawValue),
            NSNumber(value: STPCardBrand.cartesBancaires.rawValue),
            NSNumber(value: STPCardBrand.unknown.rawValue),
        ]

        for brandNumber in brands {
            let brand = STPCardBrand(rawValue: brandNumber.intValue)
            let string = STPCardBrandUtilities.stringFrom(brand!)

            switch brand {
            case .amex:
                XCTAssertEqual(string, "American Express")
            case .dinersClub:
                XCTAssertEqual(string, "Diners Club")
            case .discover:
                XCTAssertEqual(string, "Discover")
            case .JCB:
                XCTAssertEqual(string, "JCB")
            case .mastercard:
                XCTAssertEqual(string, "Mastercard")
            case .unionPay:
                XCTAssertEqual(string, "UnionPay")
            case .visa:
                XCTAssertEqual(string, "Visa")
            case .cartesBancaires:
                XCTAssertEqual(string, "Cartes Bancaires")
            case .unknown:
                XCTAssertEqual(string, "Unknown")
            @unknown default:
                break
            }
        }
    }
}
