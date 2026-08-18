//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPFPXBankBrandTest.m
//  StripeiOS Tests
//
//  Created by David Estes on 8/26/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments

class STPFPXBankBrandTest: XCTestCase {
    /// Expected API identifier and display name for every bank brand.
    private static let expectedValues: [STPFPXBankBrand: (id: String, name: String)] = [
        .affinBank: (id: "affin_bank", name: "Affin Bank"),
        .allianceBank: (id: "alliance_bank", name: "Alliance Bank"),
        .ambank: (id: "ambank", name: "AmBank"),
        .bankIslam: (id: "bank_islam", name: "Bank Islam"),
        .bankMuamalat: (id: "bank_muamalat", name: "Bank Muamalat"),
        .bankRakyat: (id: "bank_rakyat", name: "Bank Rakyat"),
        .BSN: (id: "bsn", name: "BSN"),
        .CIMB: (id: "cimb", name: "CIMB Clicks"),
        .hongLeongBank: (id: "hong_leong_bank", name: "Hong Leong Bank"),
        .HSBC: (id: "hsbc", name: "HSBC BANK"),
        .KFH: (id: "kfh", name: "KFH"),
        .maybank2E: (id: "maybank2e", name: "Maybank2E"),
        .maybank2U: (id: "maybank2u", name: "Maybank2U"),
        .ocbc: (id: "ocbc", name: "OCBC Bank"),
        .publicBank: (id: "public_bank", name: "Public Bank"),
        .RHB: (id: "rhb", name: "RHB Bank"),
        .standardChartered: (id: "standard_chartered", name: "Standard Chartered"),
        .UOB: (id: "uob", name: "UOB Bank"),
        .agrobank: (id: "agrobank", name: "Agrobank"),
        .bankOfChina: (id: "bank_of_china", name: "Bank of China"),
        .mbsbBank: (id: "mbsb_bank", name: "MBSB Bank"),        
        .unknown: (id: "unknown", name: "Unknown"),
    ]

    func testStringFromBrand() {
        for brand in STPFPXBankBrand.allCases {
            let brandName = STPFPXBank.stringFrom(brand)
            let brandID = STPFPXBank.identifierFrom(brand)
            let reverseTransformedBrand = STPFPXBank.brandFrom(brandID)
            XCTAssertEqual(reverseTransformedBrand, brand)

            if let expected = Self.expectedValues[brand] {
                XCTAssertEqual(brandID, expected.id)
                XCTAssertEqual(brandName, expected.name)
            }
        }
    }
}
