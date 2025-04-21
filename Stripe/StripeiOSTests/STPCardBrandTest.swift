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
            case .unknown:
                XCTAssertEqual(string, "unknown")
            @unknown default:
                break
            }
        }
    }
}
