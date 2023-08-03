//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPFPXBankBrandTest.swift
//  StripeiOS Tests
//
//  Created by David Estes on 8/26/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPFPXBankBrandTest: XCTestCase {
    func testStringFromBrand() {
        let brands = [
            NSNumber(value: STPFPXBankBrand.affinBank.rawValue),
            NSNumber(value: STPFPXBankBrand.allianceBank.rawValue),
            NSNumber(value: STPFPXBankBrand.ambank.rawValue),
            NSNumber(value: STPFPXBankBrand.bankIslam.rawValue),
            NSNumber(value: STPFPXBankBrand.bankMuamalat.rawValue),
            NSNumber(value: STPFPXBankBrand.bankRakyat.rawValue),
            NSNumber(value: STPFPXBankBrand.bsn.rawValue),
            NSNumber(value: STPFPXBankBrand.cimb.rawValue),
            NSNumber(value: STPFPXBankBrand.hongLeongBank.rawValue),
            NSNumber(value: STPFPXBankBrand.hsbc.rawValue),
            NSNumber(value: STPFPXBankBrand.kfh.rawValue),
            NSNumber(value: STPFPXBankBrand.maybank2E.rawValue),
            NSNumber(value: STPFPXBankBrand.maybank2U.rawValue),
            NSNumber(value: STPFPXBankBrand.ocbc.rawValue),
            NSNumber(value: STPFPXBankBrand.publicBank.rawValue),
            NSNumber(value: STPFPXBankBrand.cimb.rawValue),
            NSNumber(value: STPFPXBankBrand.rhb.rawValue),
            NSNumber(value: STPFPXBankBrand.standardChartered.rawValue),
            NSNumber(value: STPFPXBankBrand.uob.rawValue),
            NSNumber(value: STPFPXBankBrand.unknown.rawValue),
        ]

        for brandNumber in brands {
            let brand = STPFPXBankBrand(rawValue: brandNumber.intValue)
            let brandName = STPFPXBank.string(from: brand)
            let brandID = STPFPXBank.identifier(from: brand)
            let reverseTransformedBrand = STPFPXBank.brand(from: brandID)
            XCTAssertEqual(reverseTransformedBrand.rawValue, brand?.rawValue ?? 0)

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
            case .bsn:
                XCTAssertEqual(brandID, "bsn")
                XCTAssertEqual(brandName, "BSN")
            case .cimb:
                XCTAssertEqual(brandID, "cimb")
                XCTAssertEqual(brandName, "CIMB Clicks")
            case .hongLeongBank:
                XCTAssertEqual(brandID, "hong_leong_bank")
                XCTAssertEqual(brandName, "Hong Leong Bank")
            case .hsbc:
                XCTAssertEqual(brandID, "hsbc")
                XCTAssertEqual(brandName, "HSBC BANK")
            case .kfh:
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
            case .rhb:
                XCTAssertEqual(brandID, "rhb")
                XCTAssertEqual(brandName, "RHB Bank")
            case .standardChartered:
                XCTAssertEqual(brandID, "standard_chartered")
                XCTAssertEqual(brandName, "Standard Chartered")
            case .uob:
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
