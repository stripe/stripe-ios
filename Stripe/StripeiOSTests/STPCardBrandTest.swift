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
            NSNumber(value: STPCardBrand.jaywan.rawValue),
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
            case .jaywan:
                XCTAssertEqual(string, "Jaywan")
            case .unknown:
                XCTAssertEqual(string, "Unknown")
            case .none:
                XCTAssertEqual(string, "Unknown")
            @unknown default:
                break
            }
        }
    }

    func testApiValueFromBrand() {
        let brands = [
            STPCardBrand.visa,
            STPCardBrand.amex,
            STPCardBrand.mastercard,
            STPCardBrand.discover,
            STPCardBrand.JCB,
            STPCardBrand.dinersClub,
            STPCardBrand.unionPay,
            STPCardBrand.cartesBancaires,
            STPCardBrand.jaywan,
            STPCardBrand.unknown,
        ]

        for brand in brands {
            let string = STPCardBrandUtilities.apiValue(from: brand)

            switch brand {
            case .amex:
                XCTAssertEqual(string, "american_express")
            case .dinersClub:
                XCTAssertEqual(string, "diners_club")
            case .discover:
                XCTAssertEqual(string, "discover")
            case .JCB:
                XCTAssertEqual(string, "jcb")
            case .mastercard:
                XCTAssertEqual(string, "mastercard")
            case .unionPay:
                XCTAssertEqual(string, "unionpay")
            case .visa:
                XCTAssertEqual(string, "visa")
            case .cartesBancaires:
                XCTAssertEqual(string, "cartes_bancaires")
            case .jaywan:
                XCTAssertEqual(string, "jaywan")
            case .unknown:
                XCTAssertEqual(string, "unknown")
            @unknown default:
                break
            }
        }
    }

    func testRawValuesAreStable() {
        // Raw values are persisted and bridged to Objective-C, so existing values must never change.
        XCTAssertEqual(STPCardBrand.visa.rawValue, 0)
        XCTAssertEqual(STPCardBrand.amex.rawValue, 1)
        XCTAssertEqual(STPCardBrand.mastercard.rawValue, 2)
        XCTAssertEqual(STPCardBrand.discover.rawValue, 3)
        XCTAssertEqual(STPCardBrand.JCB.rawValue, 4)
        XCTAssertEqual(STPCardBrand.dinersClub.rawValue, 5)
        XCTAssertEqual(STPCardBrand.unionPay.rawValue, 6)
        XCTAssertEqual(STPCardBrand.cartesBancaires.rawValue, 7)
        XCTAssertEqual(STPCardBrand.unknown.rawValue, 8)
        XCTAssertEqual(STPCardBrand.jaywan.rawValue, 9)
        XCTAssertEqual(STPCardBrand(rawValue: 9), .jaywan)
        XCTAssertNil(STPCardBrand(rawValue: 10))
    }

    func testCodableRoundTrip() throws {
        for brand in STPCardBrand.allCases {
            // When
            let data = try JSONEncoder().encode([brand])
            let decoded = try JSONDecoder().decode([STPCardBrand].self, from: data)
            // Then
            XCTAssertEqual(decoded, [brand])
            XCTAssertEqual(String(data: data, encoding: .utf8), "[\(brand.rawValue)]")
        }
        // Previously encoded values keep decoding to the same brands
        let legacyData = try XCTUnwrap("[7,8]".data(using: .utf8))
        XCTAssertEqual(try JSONDecoder().decode([STPCardBrand].self, from: legacyData), [.cartesBancaires, .unknown])
    }

    func testJaywan() {
        XCTAssertEqual(STPCardBrandUtilities.stringFrom(.jaywan), "Jaywan")
        XCTAssertEqual(STPCardBrandUtilities.apiValue(from: .jaywan), "jaywan")
        XCTAssertEqual(STPCard.brand(from: STPCardBrandUtilities.apiValue(from: .jaywan)), .jaywan)
        XCTAssertEqual(STPCard.string(from: .jaywan), "Jaywan")
        XCTAssertEqual(STPCardBrand.jaywan.description, "jaywan")
        XCTAssertTrue(STPCardBrand.allCases.contains(.jaywan))
    }

    func testObjectiveCSelectors() {
        XCTAssertNotNil(class_getClassMethod(STPCardBrandUtilities.self, NSSelectorFromString("stringFromCardBrand:")))
        XCTAssertNotNil(class_getClassMethod(STPCardBrandUtilities.self, NSSelectorFromString("apiValueFromCardBrand:")))
        XCTAssertNotNil(class_getClassMethod(STPCard.self, NSSelectorFromString("brandFromString:")))
        XCTAssertNotNil(class_getClassMethod(STPCard.self, NSSelectorFromString("stringFromBrand:")))
    }
}
