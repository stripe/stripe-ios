//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPFPXBankBrandTest.m
//  StripeiOS Tests
//
//  Created by David Estes on 8/26/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPFPXBankBrandTest: XCTestCase {
    func testStringFromBrand() {
        let brands: [STPFPXBankBrand] = [
            .affinBank,
            .allianceBank,
            .ambank,
            .bankIslam,
            .bankMuamalat,
            .bankRakyat,
            .BSN,
            .CIMB,
            .hongLeongBank,
            .HSBC,
            .KFH,
            .maybank2E,
            .maybank2U,
            .ocbc,
            .publicBank,
            .CIMB,
            .RHB,
            .standardChartered,
            .UOB,
            .unknown,
        ]

        for brand in brands {
            let brandName = STPFPXBank.stringFrom(brand)
            let brandID = STPFPXBank.identifierFrom(brand)
            let reverseTransformedBrand = STPFPXBank.brandFrom(brandID)
            XCTAssertEqual(reverseTransformedBrand, brand)

            switch brand {
            case .affinBank:
                XCTAssertEqual(brandID, "affin_bank")
                XCTAssertEqual(brandName, "Affin Bank")
            case .allianceBank:
                XCTAssertEqual(brandID, "alliance_bank")
                XCTAssertEqual(brandName, "Alliance Bank")
            case .ambank:
                XCTAssertEqual(brandID, "ambank")
                XCTAssertEqual(brandName, "AmBank")
            case .bankIslam:
                XCTAssertEqual(brandID, "bank_islam")
                XCTAssertEqual(brandName, "Bank Islam")
            case .bankMuamalat:
                XCTAssertEqual(brandID, "bank_muamalat")
                XCTAssertEqual(brandName, "Bank Muamalat")
            case .bankRakyat:
                XCTAssertEqual(brandID, "bank_rakyat")
                XCTAssertEqual(brandName, "Bank Rakyat")
            case .BSN:
                XCTAssertEqual(brandID, "bsn")
                XCTAssertEqual(brandName, "BSN")
            case .CIMB:
                XCTAssertEqual(brandID, "cimb")
                XCTAssertEqual(brandName, "CIMB Clicks")
            case .hongLeongBank:
                XCTAssertEqual(brandID, "hong_leong_bank")
                XCTAssertEqual(brandName, "Hong Leong Bank")
            case .HSBC:
                XCTAssertEqual(brandID, "hsbc")
                XCTAssertEqual(brandName, "HSBC BANK")
            case .KFH:
                XCTAssertEqual(brandID, "kfh")
                XCTAssertEqual(brandName, "KFH")
            case .maybank2E:
                XCTAssertEqual(brandID, "maybank2e")
                XCTAssertEqual(brandName, "Maybank2E")
            case .maybank2U:
                XCTAssertEqual(brandID, "maybank2u")
                XCTAssertEqual(brandName, "Maybank2U")
            case .ocbc:
                XCTAssertEqual(brandID, "ocbc")
                XCTAssertEqual(brandName, "OCBC Bank")
            case .publicBank:
                XCTAssertEqual(brandID, "public_bank")
                XCTAssertEqual(brandName, "Public Bank")
            case .RHB:
                XCTAssertEqual(brandID, "rhb")
                XCTAssertEqual(brandName, "RHB Bank")
            case .standardChartered:
                XCTAssertEqual(brandID, "standard_chartered")
                XCTAssertEqual(brandName, "Standard Chartered")
            case .UOB:
                XCTAssertEqual(brandID, "uob")
                XCTAssertEqual(brandName, "UOB Bank")
            case .unknown:
                XCTAssertEqual(brandID, "unknown")
                XCTAssertEqual(brandName, "Unknown")
            @unknown default:
                break
            }
        }
    }
}
